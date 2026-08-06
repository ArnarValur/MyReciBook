// Remote mirror of the user's folder (arch §4: the SAF folder IS the sync
// surface — Drive/Dropbox mirror it). Names are the folder-relative layout
// ('<id>.json', 'images/<id>-<n>.jpg'); each provider maps them onto its own
// storage. AuthedClient owns tokens: proactive refresh, one 401 retry
// persisting the RETURNED TokenSet (providers omit refresh_token on refresh),
// bounded backoff on 429/5xx/transport (rule 4 heritage). Failures are typed:
// SyncIoException = transient (engine goes offline, resumes next pass),
// AuthRevokedException = re-connect flow (§7 — never a crash).

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'oauth.dart';
import 'token_store.dart';

export 'oauth.dart' show AuthRevokedException;

/// Transient transport/provider failure — sync reports offline, keeps the
/// manifest intact and resumes on the next pass (§7).
class SyncIoException implements Exception {
  final String message;

  SyncIoException(this.message);

  @override
  String toString() => 'SyncIoException: $message';
}

/// One remote file, keyed by relative name. [rev] is the provider's change
/// token (Drive md5Checksum/headRevisionId, Dropbox content_hash/rev).
class RemoteEntry {
  final String name;
  final int size;
  final String rev;

  const RemoteEntry({required this.name, required this.size, required this.rev});
}

/// Provider-agnostic mirror of the folder layout. delete() is idempotent —
/// a name already gone remotely is success, not an error.
abstract class RemoteStore {
  Future<Map<String, RemoteEntry>> list();
  Future<void> upload(String name, List<int> bytes);
  Future<List<int>> download(String name);
  Future<void> delete(String name);
}

/// http.Client wrapper with the token lifecycle. [build] must construct a
/// FRESH request per call — a sent http.Request can't be replayed.
class AuthedClient {
  AuthedClient({
    required this.provider,
    required this.flow,
    required this.tokenStore,
    required this.tokenKey,
    http.Client? client,
    Future<void> Function(Duration)? wait,
  })  : _client = client ?? http.Client(),
        _wait = wait ?? ((d) => Future<void>.delayed(d));

  static const _maxTries = 3;

  final OAuthProvider provider;
  final OAuthFlow flow;
  final TokenStore tokenStore;

  /// TokenStore key: 'drive' / 'dropbox'.
  final String tokenKey;

  final http.Client _client;
  final Future<void> Function(Duration) _wait;

  Future<String> _accessToken({bool forceRefresh = false}) async {
    var tokens = tokenStore.tokens(tokenKey);
    if (tokens == null) {
      throw const AuthRevokedException('not connected');
    }
    if (forceRefresh || tokens.isExpired) {
      try {
        tokens = await flow.refresh(provider, tokens);
      } on AuthRevokedException {
        rethrow;
      } on OAuthException catch (e) {
        // Refresh failed for transport-ish reasons: offline, not revoked.
        throw SyncIoException('token refresh failed: ${e.message}');
      }
      // Persist the RETURNED set — it carries the kept refresh token.
      await tokenStore.setTokens(tokenKey, tokens);
    }
    return tokens.accessToken;
  }

  /// Sends [build]'s request with a Bearer token. 401 → refresh + retry once,
  /// second 401 → AuthRevokedException. 429/5xx/transport → bounded backoff,
  /// then SyncIoException. Any other status returns to the caller.
  Future<http.Response> send(http.Request Function() build) async {
    var token = await _accessToken();
    var refreshed = false;
    var tries = 0;
    while (true) {
      http.Response resp;
      try {
        final req = build();
        req.headers['Authorization'] = 'Bearer $token';
        resp = await http.Response.fromStream(await _client.send(req));
      } catch (e) {
        tries++;
        if (tries >= _maxTries) throw SyncIoException('request failed: $e');
        await _wait(_backoff(tries));
        continue;
      }
      if (resp.statusCode == 401) {
        if (refreshed) {
          throw const AuthRevokedException('401 with a fresh token');
        }
        refreshed = true;
        token = await _accessToken(forceRefresh: true);
        continue;
      }
      if (resp.statusCode == 429 || resp.statusCode >= 500) {
        tries++;
        if (tries >= _maxTries) {
          throw SyncIoException('HTTP ${resp.statusCode} after $tries tries');
        }
        await _wait(_backoff(tries));
        continue;
      }
      return resp;
    }
  }

  Duration _backoff(int tries) => Duration(milliseconds: 500 * tries * tries);
}

String _bodyText(http.Response resp) =>
    utf8.decode(resp.bodyBytes, allowMalformed: true); // rule 7

http.Response _ok(http.Response resp, String what) {
  if (resp.statusCode >= 200 && resp.statusCode < 300) return resp;
  final body = _bodyText(resp);
  throw SyncIoException('$what: HTTP ${resp.statusCode} '
      '${body.length <= 160 ? body : body.substring(0, 160)}');
}

String _mimeFor(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.json')) return 'application/json';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}

/// Google Drive mirror (REST v3, drive.file scope). drive.file only surfaces
/// files this app created — that IS the design: the app-visible layout is
/// 'MyReciBook/recipes' (6e, turn 6) — a `folderName` root folder whose
/// 'recipes' child holds the json files, with its 'images' child holding the
/// images.
class DriveRemote implements RemoteStore {
  DriveRemote(this._client, {this.folderName = 'MyReciBook'});

  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';
  static const _folderMime = 'application/vnd.google-apps.folder';
  static const _recipesFolder = 'recipes';

  final AuthedClient _client;
  final String folderName;

  // Session caches: folder ids ensured once; file ids from list() decide
  // multipart-create vs media-update.
  String? _rootId;
  String? _recipesId;
  String? _imagesId;
  bool _listed = false;
  final Map<String, String> _fileIds = {}; // relative name → drive file id

  Future<List<Map<String, dynamic>>> _query(String q) async {
    final files = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final uri = Uri.parse('$_api/files').replace(queryParameters: {
        'q': q,
        'fields':
            'nextPageToken,files(id,name,mimeType,md5Checksum,headRevisionId,size)',
        'pageSize': '1000',
        'pageToken': ?pageToken,
      });
      final resp = _ok(
          await _client.send(() => http.Request('GET', uri)), 'drive list');
      final json = jsonDecode(_bodyText(resp)) as Map<String, dynamic>;
      files.addAll([
        for (final f in json['files'] as List? ?? const [])
          (f as Map).cast<String, dynamic>()
      ]);
      pageToken = json['nextPageToken'] as String?;
    } while (pageToken != null);
    return files;
  }

  Future<String> _createFolder(String name, String? parentId) async {
    final resp = _ok(
        await _client.send(() => http.Request('POST', Uri.parse('$_api/files'))
          ..headers['Content-Type'] = 'application/json; charset=utf-8'
          ..body = jsonEncode({
            'name': name,
            'mimeType': _folderMime,
            if (parentId != null) 'parents': [parentId],
          })),
        'drive create folder $name');
    return (jsonDecode(_bodyText(resp)) as Map)['id'] as String;
  }

  Future<String> _ensureRootId() async {
    if (_rootId != null) return _rootId!;
    final found = await _query("name = '$folderName' and "
        "mimeType = '$_folderMime' and 'root' in parents and trashed = false");
    if (found.isNotEmpty) return _rootId = found.first['id'] as String;
    return _rootId = await _createFolder(folderName, null);
  }

  Future<String> _ensureRecipesId() async {
    if (_recipesId != null) return _recipesId!;
    final rootId = await _ensureRootId();
    final found = await _query("name = '$_recipesFolder' and "
        "mimeType = '$_folderMime' and '$rootId' in parents and trashed = false");
    if (found.isNotEmpty) return _recipesId = found.first['id'] as String;
    return _recipesId = await _createFolder(_recipesFolder, rootId);
  }

  Future<String> _ensureImagesId() async {
    if (_imagesId != null) return _imagesId!;
    final recipesId = await _ensureRecipesId();
    final found = await _query("name = 'images' and "
        "mimeType = '$_folderMime' and '$recipesId' in parents and trashed = false");
    if (found.isNotEmpty) return _imagesId = found.first['id'] as String;
    return _imagesId = await _createFolder('images', recipesId);
  }

  Future<String?> _idFor(String name) async {
    if (!_listed && !_fileIds.containsKey(name)) await list();
    return _fileIds[name];
  }

  @override
  Future<Map<String, RemoteEntry>> list() async {
    final recipesId = await _ensureRecipesId();
    final entries = <String, RemoteEntry>{};
    _fileIds.clear();
    void add(String name, Map<String, dynamic> f) {
      _fileIds[name] = f['id'] as String;
      entries[name] = RemoteEntry(
        name: name,
        size: int.tryParse('${f['size'] ?? ''}') ?? 0,
        rev: (f['md5Checksum'] ?? f['headRevisionId'] ?? '') as String,
      );
    }

    for (final f
        in await _query("'$recipesId' in parents and trashed = false")) {
      if (f['mimeType'] == _folderMime) {
        if (f['name'] == 'images') _imagesId = f['id'] as String;
        continue;
      }
      add(f['name'] as String, f);
    }
    if (_imagesId != null) {
      for (final f
          in await _query("'$_imagesId' in parents and trashed = false")) {
        if (f['mimeType'] == _folderMime) continue;
        add('images/${f['name']}', f);
      }
    }
    _listed = true;
    return entries;
  }

  @override
  Future<void> upload(String name, List<int> bytes) async {
    final existing = await _idFor(name);
    if (existing != null) {
      // Known file: media update in place keeps the id (and sharing) stable.
      final uri = Uri.parse('$_uploadApi/files/$existing?uploadType=media');
      _ok(
          await _client.send(() => http.Request('PATCH', uri)
            ..headers['Content-Type'] = _mimeFor(name)
            ..bodyBytes = bytes),
          'drive update $name');
      return;
    }
    final isImage = name.startsWith('images/');
    final parentId =
        isImage ? await _ensureImagesId() : await _ensureRecipesId();
    final leaf = isImage ? name.substring('images/'.length) : name;
    final boundary = 'myrecibook-${DateTime.now().microsecondsSinceEpoch}';
    final body = BytesBuilder(copy: false)
      ..add(utf8.encode('--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '${jsonEncode({'name': leaf, 'parents': [parentId]})}\r\n'
          '--$boundary\r\n'
          'Content-Type: ${_mimeFor(name)}\r\n\r\n'))
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));
    final payload = body.toBytes();
    final resp = _ok(
        await _client.send(() => http.Request(
            'POST', Uri.parse('$_uploadApi/files?uploadType=multipart'))
          ..headers['Content-Type'] = 'multipart/related; boundary=$boundary'
          ..bodyBytes = payload),
        'drive create $name');
    final id = (jsonDecode(_bodyText(resp)) as Map)['id'];
    if (id is String) _fileIds[name] = id;
  }

  @override
  Future<List<int>> download(String name) async {
    final id = await _idFor(name);
    if (id == null) throw SyncIoException('drive download $name: not found');
    final resp = _ok(
        await _client.send(
            () => http.Request('GET', Uri.parse('$_api/files/$id?alt=media'))),
        'drive download $name');
    return resp.bodyBytes;
  }

  @override
  Future<void> delete(String name) async {
    final id = await _idFor(name);
    if (id == null) return; // already gone
    final resp = await _client
        .send(() => http.Request('DELETE', Uri.parse('$_api/files/$id')));
    if (resp.statusCode != 404) _ok(resp, 'drive delete $name');
    _fileIds.remove(name);
  }
}

// Dropbox-API-Arg headers are JSON but must be ASCII — escape everything
// outside 0x20–0x7E as \uXXXX per their spec (recipe names carry 'Kjötsúpa').
String _asciiArg(Map<String, Object?> value) {
  final json = jsonEncode(value);
  final sb = StringBuffer();
  for (final code in json.runes) {
    if (code >= 0x20 && code <= 0x7e) {
      sb.writeCharCode(code);
    } else if (code > 0xffff) {
      final c = code - 0x10000;
      sb.write('\\u${(0xd800 + (c >> 10)).toRadixString(16).padLeft(4, '0')}');
      sb.write('\\u${(0xdc00 + (c & 0x3ff)).toRadixString(16).padLeft(4, '0')}');
    } else {
      sb.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
    }
  }
  return sb.toString();
}

/// Dropbox mirror (App-folder access type). The layout lives in a 'recipes'
/// child of the app folder — `/recipes/<name>` — so the on-Dropbox truth is
/// 'Apps/MyReciBook/recipes' (6e, turn 6). Upload creates the folder
/// implicitly; a missing folder on list is simply an empty mirror.
class DropboxRemote implements RemoteStore {
  DropboxRemote(this._client);

  static const _api = 'https://api.dropboxapi.com/2';
  static const _content = 'https://content.dropboxapi.com/2';
  static const _prefix = 'recipes/'; // app-folder-relative layout root

  final AuthedClient _client;

  @override
  Future<Map<String, RemoteEntry>> list() async {
    final entries = <String, RemoteEntry>{};
    var uri = Uri.parse('$_api/files/list_folder');
    var body = jsonEncode({'path': '/recipes', 'recursive': true});
    var first = true;
    while (true) {
      final u = uri;
      final b = body;
      final resp = await _client.send(() => http.Request('POST', u)
        ..headers['Content-Type'] = 'application/json'
        ..body = b);
      // Nothing mirrored yet: the recipes folder doesn't exist until the
      // first upload — an honest empty mirror, not an error.
      if (first &&
          resp.statusCode == 409 &&
          _bodyText(resp).contains('not_found')) {
        return entries;
      }
      first = false;
      _ok(resp, 'dropbox list');
      final json = jsonDecode(_bodyText(resp)) as Map<String, dynamic>;
      for (final raw in json['entries'] as List? ?? const []) {
        final e = (raw as Map).cast<String, dynamic>();
        if (e['.tag'] != 'file') continue;
        final path = (e['path_display'] ?? e['path_lower'] ?? '') as String;
        if (path.isEmpty) continue;
        var name = path.startsWith('/') ? path.substring(1) : path;
        if (!name.startsWith(_prefix)) continue; // outside the layout root
        name = name.substring(_prefix.length);
        entries[name] = RemoteEntry(
          name: name,
          size: (e['size'] as num?)?.toInt() ?? 0,
          rev: (e['content_hash'] ?? e['rev'] ?? '') as String,
        );
      }
      if (json['has_more'] != true) return entries;
      uri = Uri.parse('$_api/files/list_folder/continue');
      body = jsonEncode({'cursor': json['cursor']});
    }
  }

  @override
  Future<void> upload(String name, List<int> bytes) async {
    _ok(
        await _client.send(() => http.Request(
            'POST', Uri.parse('$_content/files/upload'))
          ..headers['Dropbox-API-Arg'] = _asciiArg(
              {'path': '/$_prefix$name', 'mode': 'overwrite', 'mute': true})
          ..headers['Content-Type'] = 'application/octet-stream'
          ..bodyBytes = bytes),
        'dropbox upload $name');
  }

  @override
  Future<List<int>> download(String name) async {
    final resp = _ok(
        await _client.send(() =>
            http.Request('POST', Uri.parse('$_content/files/download'))
              ..headers['Dropbox-API-Arg'] =
                  _asciiArg({'path': '/$_prefix$name'})),
        'dropbox download $name');
    return resp.bodyBytes;
  }

  @override
  Future<void> delete(String name) async {
    final resp = await _client
        .send(() => http.Request('POST', Uri.parse('$_api/files/delete_v2'))
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({'path': '/$_prefix$name'}));
    // Already gone → success: delete is idempotent by contract.
    if (resp.statusCode == 409 && _bodyText(resp).contains('not_found')) return;
    _ok(resp, 'dropbox delete $name');
  }
}
