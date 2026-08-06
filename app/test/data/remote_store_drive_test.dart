// DriveRemote against an in-memory Drive v3 fake: folder ensure, pagination,
// multipart-create vs media-update, and AuthedClient's token lifecycle
// (401 → refresh → retry once, persisted returned set; bounded 5xx backoff).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/oauth.dart';
import 'package:myrecibook/data/remote_store.dart';
import 'package:myrecibook/data/token_store.dart';

const _folderMime = 'application/vnd.google-apps.folder';

String? _header(http.Request req, String name) {
  for (final e in req.headers.entries) {
    if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
  }
  return null;
}

class _Folder {
  _Folder(this.name, this.parent);
  final String name;
  final String? parent; // null = Drive root
}

class _DriveFile {
  _DriveFile(this.name, this.parent, this.bytes);
  final String name;
  final String parent;
  List<int> bytes;

  String get md5 =>
      'h${bytes.length}-${bytes.fold<int>(0, (a, b) => (a * 31 + b) & 0xffffff)}';
}

class FakeDrive {
  final folders = <String, _Folder>{};
  final files = <String, _DriveFile>{};
  final validTokens = <String>{'at-1'};
  int folderSearches = 0;
  int createUploads = 0;
  int mediaUpdates = 0;
  int requests = 0;
  int failNext = 0; // respond 503 to the next N requests
  int pageSize = 2; // small on purpose — forces the pageToken loop
  int _seq = 0;

  String addFolder(String name, {String? parent}) {
    final id = 'fld-${++_seq}';
    folders[id] = _Folder(name, parent);
    return id;
  }

  String addFile(String name, String parent, List<int> bytes) {
    final id = 'fil-${++_seq}';
    files[id] = _DriveFile(name, parent, bytes);
    return id;
  }

  Future<http.Response> call(http.Request req) async {
    requests++;
    if (failNext > 0) {
      failNext--;
      return http.Response('service unavailable', 503);
    }
    final token = (_header(req, 'Authorization') ?? '').replaceFirst('Bearer ', '');
    if (!validTokens.contains(token)) {
      return http.Response('{"error": {"code": 401}}', 401);
    }
    final uri = req.url;
    if (req.method == 'GET' && uri.path == '/drive/v3/files') {
      return _list(uri);
    }
    if (req.method == 'POST' && uri.path == '/drive/v3/files') {
      final meta = jsonDecode(utf8.decode(req.bodyBytes)) as Map;
      final id = addFolder(meta['name'] as String,
          parent: (meta['parents'] as List?)?.first as String?);
      return http.Response(jsonEncode({'id': id}), 200);
    }
    if (req.method == 'POST' && uri.path == '/upload/drive/v3/files') {
      createUploads++;
      return _multipartCreate(req);
    }
    if (req.method == 'PATCH' && uri.path.startsWith('/upload/drive/v3/files/')) {
      mediaUpdates++;
      final f = files[uri.pathSegments.last];
      if (f == null) return http.Response('not found', 404);
      f.bytes = req.bodyBytes;
      return http.Response('{}', 200);
    }
    if (req.method == 'GET' &&
        uri.path.startsWith('/drive/v3/files/') &&
        uri.queryParameters['alt'] == 'media') {
      final f = files[uri.pathSegments.last];
      if (f == null) return http.Response('not found', 404);
      return http.Response.bytes(f.bytes, 200);
    }
    if (req.method == 'DELETE' && uri.path.startsWith('/drive/v3/files/')) {
      files.remove(uri.pathSegments.last);
      folders.remove(uri.pathSegments.last);
      return http.Response('', 204);
    }
    return http.Response('unhandled ${req.method} ${uri.path}', 500);
  }

  http.Response _list(Uri uri) {
    final q = uri.queryParameters['q'] ?? '';
    final parent = RegExp(r"'([^']+)' in parents").firstMatch(q)?.group(1);
    if (q.contains("mimeType = '$_folderMime'") && q.contains('name =')) {
      folderSearches++;
      final name = RegExp(r"name = '([^']+)'").firstMatch(q)!.group(1);
      final hits = [
        for (final e in folders.entries)
          if (e.value.name == name &&
              (parent == 'root'
                  ? e.value.parent == null
                  : e.value.parent == parent))
            {'id': e.key, 'name': e.value.name, 'mimeType': _folderMime}
      ];
      return http.Response(jsonEncode({'files': hits}), 200);
    }
    final children = <Map<String, Object?>>[
      for (final e in folders.entries)
        if (e.value.parent == parent)
          {'id': e.key, 'name': e.value.name, 'mimeType': _folderMime},
      for (final e in files.entries)
        if (e.value.parent == parent)
          {
            'id': e.key,
            'name': e.value.name,
            'mimeType': 'application/octet-stream',
            'md5Checksum': e.value.md5,
            'size': '${e.value.bytes.length}',
          },
    ];
    final start = int.tryParse(uri.queryParameters['pageToken'] ?? '') ?? 0;
    final page = children.skip(start).take(pageSize).toList();
    final more = start + pageSize < children.length;
    return http.Response(
        jsonEncode({
          'files': page,
          if (more) 'nextPageToken': '${start + pageSize}',
        }),
        200);
  }

  http.Response _multipartCreate(http.Request req) {
    final ct = _header(req, 'Content-Type') ?? '';
    final boundary = RegExp(r'boundary=(.+)$').firstMatch(ct)!.group(1)!;
    final parts = utf8.decode(req.bodyBytes).split('--$boundary');
    String content(String part) {
      var c = part.substring(part.indexOf('\r\n\r\n') + 4);
      return c.endsWith('\r\n') ? c.substring(0, c.length - 2) : c;
    }

    final meta = jsonDecode(content(parts[1])) as Map;
    final parentId = (meta['parents'] as List).first as String;
    if (!folders.containsKey(parentId)) {
      return http.Response('bad parent $parentId', 400);
    }
    final id =
        addFile(meta['name'] as String, parentId, utf8.encode(content(parts[2])));
    return http.Response(jsonEncode({'id': id}), 200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const authChannel = MethodChannel('fake-auth-drive-test');

  late Directory tmp;
  late FakeDrive drive;
  late TokenStore tokens;
  late File tokenFile;
  late List<Duration> waits;
  late int refreshes;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('drive-test');
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<DriveRemote> makeRemote({TokenSet? seed}) async {
    drive = FakeDrive();
    tokenFile = File('${tmp.path}/tokens.json');
    tokens = await TokenStore.load(tokenFile);
    await tokens.setTokens('drive',
        seed ?? const TokenSet(accessToken: 'at-1', refreshToken: 'rt-1'));
    waits = [];
    refreshes = 0;
    final flow = OAuthFlow(
      channel: authChannel,
      client: MockClient((req) async {
        refreshes++;
        return http.Response(
            jsonEncode({'access_token': 'at-2', 'expires_in': 3600}), 200);
      }),
    );
    return DriveRemote(AuthedClient(
      provider: OAuthProvider.googleDrive('gid.apps.googleusercontent.com'),
      flow: flow,
      tokenStore: tokens,
      tokenKey: 'drive',
      client: MockClient(drive.call),
      wait: (d) async => waits.add(d),
    ));
  }

  test('list paginates and maps both dirs to relative names', () async {
    final remote = await makeRemote();
    final root = drive.addFolder('MyReciBook');
    final img = drive.addFolder('images', parent: root);
    drive.addFile('a.json', root, utf8.encode('{"a":1}'));
    drive.addFile('b.json', root, utf8.encode('{"b":22}'));
    drive.addFile('c.json', root, utf8.encode('{"c":3}'));
    drive.addFile('x-1.jpg', img, [1, 2, 3]);

    final listed = await remote.list();
    expect(listed.keys.toSet(),
        {'a.json', 'b.json', 'c.json', 'images/x-1.jpg'});
    expect(listed['a.json']!.size, 7);
    expect(listed['b.json']!.rev, isNotEmpty);
    expect(listed['images/x-1.jpg']!.size, 3);
    // pageSize 2 with 4 root children means the pageToken loop actually ran.
    expect(drive.folderSearches, 1);
  });

  test('folder layout ensured lazily, exactly once', () async {
    final remote = await makeRemote(); // empty Drive
    await remote.list();
    await remote.list();
    await remote.upload('r.json', utf8.encode('{}'));
    expect(drive.folderSearches, 1); // root searched once, then cached

    await remote.upload('images/x-1.jpg', utf8.encode('img'));
    await remote.upload('images/y-1.jpg', utf8.encode('img2'));
    expect(drive.folderSearches, 2); // + one images search, then cached
    expect(drive.folders.length, 2); // MyReciBook + images, no duplicates
  });

  test('new name → multipart create; known name → media update', () async {
    final remote = await makeRemote();
    await remote.upload('a.json', utf8.encode('v1'));
    expect(drive.createUploads, 1);
    expect(drive.mediaUpdates, 0);

    await remote.upload('a.json', utf8.encode('v2-longer'));
    expect(drive.createUploads, 1);
    expect(drive.mediaUpdates, 1);
    final f = drive.files.values.single;
    expect(f.name, 'a.json');
    expect(utf8.decode(f.bytes), 'v2-longer');
  });

  test('update goes to the fileId learned from list()', () async {
    final remote = await makeRemote();
    final root = drive.addFolder('MyReciBook');
    final id = drive.addFile('a.json', root, utf8.encode('old'));
    await remote.list();
    await remote.upload('a.json', utf8.encode('new'));
    expect(drive.createUploads, 0);
    expect(utf8.decode(drive.files[id]!.bytes), 'new');
  });

  test('download via alt=media returns exact bytes', () async {
    final remote = await makeRemote();
    final root = drive.addFolder('MyReciBook');
    final bytes = utf8.encode('portion: ½ cup'); // rule 7 payload
    drive.addFile('a.json', root, bytes);
    expect(await remote.download('a.json'), bytes);
  });

  test('delete removes the file; deleting a missing name is a no-op',
      () async {
    final remote = await makeRemote();
    final root = drive.addFolder('MyReciBook');
    drive.addFile('a.json', root, utf8.encode('{}'));
    await remote.delete('a.json');
    expect(drive.files, isEmpty);
    await remote.delete('a.json'); // idempotent — no throw
  });

  test('401 → refresh → retry once; RETURNED TokenSet persisted to disk',
      () async {
    final remote = await makeRemote();
    drive.validTokens
      ..clear()
      ..add('at-2'); // stored at-1 is stale
    drive.addFolder('MyReciBook');

    await remote.list();
    expect(refreshes, 1);
    expect(tokens.tokens('drive')!.accessToken, 'at-2');
    final reloaded = await TokenStore.load(tokenFile);
    expect(reloaded.tokens('drive')!.accessToken, 'at-2');
    // Provider omitted refresh_token on refresh — the old one must survive.
    expect(reloaded.tokens('drive')!.refreshToken, 'rt-1');
  });

  test('second 401 after a fresh token → AuthRevokedException', () async {
    final remote = await makeRemote();
    drive.validTokens.clear(); // nothing is ever valid
    await expectLater(remote.list(), throwsA(isA<AuthRevokedException>()));
    expect(refreshes, 1); // exactly one refresh attempt, then revoked
  });

  test('503 storm: bounded to 3 tries with growing backoff', () async {
    final remote = await makeRemote();
    drive.failNext = 99;
    await expectLater(remote.list(), throwsA(isA<SyncIoException>()));
    expect(drive.requests, 3);
    expect(waits, hasLength(2));
    expect(waits[1], greaterThan(waits[0]));
  });

  test('single 503 recovers on retry (rule 4 heritage)', () async {
    final remote = await makeRemote();
    drive.addFolder('MyReciBook');
    drive.failNext = 1;
    await remote.list();
    expect(waits, hasLength(1));
  });

  test('transport exceptions become SyncIoException after bounded tries',
      () async {
    await makeRemote();
    final authed = AuthedClient(
      provider: OAuthProvider.googleDrive('gid.apps.googleusercontent.com'),
      flow: OAuthFlow(channel: authChannel, client: MockClient((_) async {
        return http.Response('{}', 200);
      })),
      tokenStore: tokens,
      tokenKey: 'drive',
      client: MockClient((_) async => throw http.ClientException('net down')),
      wait: (d) async => waits.add(d),
    );
    await expectLater(
      DriveRemote(authed).list(),
      throwsA(isA<SyncIoException>()),
    );
    expect(waits, hasLength(2));
  });
}
