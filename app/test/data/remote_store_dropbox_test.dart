// DropboxRemote against an in-memory RPC/content fake: the /recipes layout
// (6e: app-folder truth 'Apps/MyReciBook/recipes'), list_folder + continue,
// the not-yet-created folder listing as empty, overwrite upload, the
// ASCII-escaped Dropbox-API-Arg header (recipes are titled 'Kjötsúpa' around
// here), and the 401 refresh path.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/oauth.dart';
import 'package:myrecibook/data/remote_store.dart';
import 'package:myrecibook/data/token_store.dart';

String? _header(http.Request req, String name) {
  for (final e in req.headers.entries) {
    if (e.key.toLowerCase() == name.toLowerCase()) return e.value;
  }
  return null;
}

class FakeDropbox {
  final files = <String, List<int>>{}; // app-folder-relative path → bytes
  final validTokens = <String>{'at-1'};
  final apiArgs = <String>[]; // every Dropbox-API-Arg header, verbatim
  Map<String, dynamic>? lastListBody;
  String listPrefix = ''; // folder scope of the in-flight list
  int listCalls = 0;
  int continueCalls = 0;
  int pageSize = 2;

  Future<http.Response> call(http.Request req) async {
    final token =
        (_header(req, 'Authorization') ?? '').replaceFirst('Bearer ', '');
    if (!validTokens.contains(token)) {
      return http.Response('{"error_summary": "expired_access_token/..."}', 401);
    }
    switch (req.url.path) {
      case '/2/files/list_folder':
        listCalls++;
        lastListBody =
            jsonDecode(utf8.decode(req.bodyBytes)) as Map<String, dynamic>;
        final path = lastListBody!['path'] as String;
        listPrefix = path.isEmpty ? '' : '${path.substring(1)}/';
        // Real Dropbox: listing a folder no upload ever created → not_found.
        if (listPrefix.isNotEmpty &&
            !files.keys.any((n) => n.startsWith(listPrefix))) {
          return http.Response(
              '{"error_summary": "path/not_found/..."}', 409);
        }
        return _page(0);
      case '/2/files/list_folder/continue':
        continueCalls++;
        final cursor =
            (jsonDecode(utf8.decode(req.bodyBytes)) as Map)['cursor'] as String;
        return _page(int.parse(cursor));
      case '/2/files/upload':
        final arg = _header(req, 'Dropbox-API-Arg')!;
        apiArgs.add(arg);
        final parsed = jsonDecode(arg) as Map;
        if (parsed['mode'] != 'overwrite') {
          return http.Response('{"error_summary": "bad_mode"}', 409);
        }
        files[(parsed['path'] as String).substring(1)] = req.bodyBytes;
        return http.Response('{"name": "x"}', 200);
      case '/2/files/download':
        final arg = _header(req, 'Dropbox-API-Arg')!;
        apiArgs.add(arg);
        final path = ((jsonDecode(arg) as Map)['path'] as String).substring(1);
        final bytes = files[path];
        if (bytes == null) {
          return http.Response('{"error_summary": "path/not_found/..."}', 409);
        }
        return http.Response.bytes(bytes, 200);
      case '/2/files/delete_v2':
        final path = ((jsonDecode(utf8.decode(req.bodyBytes)) as Map)['path']
                as String)
            .substring(1);
        if (!files.containsKey(path)) {
          return http.Response(
              '{"error_summary": "path_lookup/not_found/..."}', 409);
        }
        files.remove(path);
        return http.Response('{}', 200);
    }
    return http.Response('unhandled ${req.url.path}', 500);
  }

  http.Response _page(int start) {
    final names = files.keys.where((n) => n.startsWith(listPrefix)).toList()
      ..sort();
    final page = names.skip(start).take(pageSize).toList();
    return http.Response(
        jsonEncode({
          'entries': [
            for (final n in page)
              {
                '.tag': 'file',
                'name': n.split('/').last,
                'path_display': '/$n',
                'path_lower': '/${n.toLowerCase()}',
                'size': files[n]!.length,
                'content_hash': 'ch-$n',
                'rev': 'r-$n',
              },
          ],
          'cursor': '${start + pageSize}',
          'has_more': start + pageSize < names.length,
        }),
        200);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const authChannel = MethodChannel('fake-auth-dropbox-test');

  late Directory tmp;
  late FakeDropbox dropbox;
  late TokenStore tokens;
  late File tokenFile;
  late int refreshes;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('dropbox-test');
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<DropboxRemote> makeRemote() async {
    dropbox = FakeDropbox();
    tokenFile = File('${tmp.path}/tokens.json');
    tokens = await TokenStore.load(tokenFile);
    await tokens.setTokens(
        'dropbox', const TokenSet(accessToken: 'at-1', refreshToken: 'rt-1'));
    refreshes = 0;
    final flow = OAuthFlow(
      channel: authChannel,
      client: MockClient((req) async {
        refreshes++;
        return http.Response(
            jsonEncode({'access_token': 'at-2', 'expires_in': 14400}), 200);
      }),
    );
    return DropboxRemote(AuthedClient(
      provider: OAuthProvider.dropbox('appkey-1'),
      flow: flow,
      tokenStore: tokens,
      tokenKey: 'dropbox',
      client: MockClient(dropbox.call),
      wait: (_) async {},
    ));
  }

  test('list walks list_folder + continue and maps names relative to '
      '/recipes', () async {
    final remote = await makeRemote();
    dropbox.files['recipes/a.json'] = utf8.encode('{"a":1}');
    dropbox.files['recipes/b.json'] = utf8.encode('{"b":22}');
    dropbox.files['recipes/images/x-1.jpg'] = [1, 2, 3];

    final listed = await remote.list();
    expect(dropbox.listCalls, 1);
    expect(dropbox.continueCalls, 1); // 3 entries, page size 2
    expect(dropbox.lastListBody, {'path': '/recipes', 'recursive': true});
    expect(listed.keys.toSet(), {'a.json', 'b.json', 'images/x-1.jpg'});
    expect(listed['a.json']!.size, 7);
    expect(listed['a.json']!.rev, 'ch-recipes/a.json'); // content_hash preferred
  });

  test('list before any upload: missing /recipes folder is an empty mirror, '
      'not an error', () async {
    final remote = await makeRemote(); // fresh app folder, nothing uploaded
    expect(await remote.list(), isEmpty);
  });

  test('upload writes /recipes/<name> with mode overwrite', () async {
    final remote = await makeRemote();
    await remote.upload('a.json', utf8.encode('v1'));
    expect(utf8.decode(dropbox.files['recipes/a.json']!), 'v1');

    await remote.upload('a.json', utf8.encode('v2'));
    expect(utf8.decode(dropbox.files['recipes/a.json']!), 'v2'); // overwrote
    expect(dropbox.files, hasLength(1));
    final arg = jsonDecode(dropbox.apiArgs.first) as Map;
    expect(arg['path'], '/recipes/a.json');
    expect(arg['mode'], 'overwrite');
  });

  test('non-ASCII name → ASCII-escaped Dropbox-API-Arg header', () async {
    final remote = await makeRemote();
    await remote.upload('images/Kjötsúpa-1.jpg', [1, 2]);

    final header = dropbox.apiArgs.single;
    expect(header.codeUnits.every((c) => c >= 0x20 && c <= 0x7e), isTrue,
        reason: 'header must be pure printable ASCII: $header');
    expect(header, contains('\\u00f6')); // ö
    expect(header, contains('\\u00fa')); // ú
    // The escaping is lossless: the fake stored it under the unicode path.
    expect(dropbox.files.keys.single, 'recipes/images/Kjötsúpa-1.jpg');
  });

  test('download returns exact bytes for a non-ASCII path', () async {
    final remote = await makeRemote();
    final bytes = utf8.encode('kjöt í súpu ½');
    dropbox.files['recipes/images/Kjötsúpa-1.jpg'] = bytes;
    expect(await remote.download('images/Kjötsúpa-1.jpg'), bytes);
  });

  test('delete removes; deleting a missing path is a no-op', () async {
    final remote = await makeRemote();
    dropbox.files['recipes/a.json'] = utf8.encode('{}');
    await remote.delete('a.json');
    expect(dropbox.files, isEmpty);
    await remote.delete('a.json'); // 409 not_found → swallowed
  });

  test('401 → refresh → retry; refreshed set persisted', () async {
    final remote = await makeRemote();
    dropbox.validTokens
      ..clear()
      ..add('at-2');
    await remote.upload('a.json', utf8.encode('{}'));
    expect(refreshes, 1);
    expect(utf8.decode(dropbox.files['recipes/a.json']!), '{}');
    final reloaded = await TokenStore.load(tokenFile);
    expect(reloaded.tokens('dropbox')!.accessToken, 'at-2');
    expect(reloaded.tokens('dropbox')!.refreshToken, 'rt-1');
  });

  test('second 401 → AuthRevokedException', () async {
    final remote = await makeRemote();
    dropbox.validTokens.clear();
    await expectLater(
        remote.list(), throwsA(isA<AuthRevokedException>()));
    expect(refreshes, 1);
  });
}
