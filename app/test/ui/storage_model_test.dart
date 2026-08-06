// StorageModel over the real stage-1/2 layers: fake auth channel + MockClient
// token endpoint for connect, FakeRemote + real SyncEngine over a temp folder
// for sync/restore. The honesty invariants are the point: every state the
// model reports must have actually happened.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/oauth.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/remote_store.dart';
import 'package:myrecibook/data/saf_store.dart' show GrantLostException;
import 'package:myrecibook/data/sync_engine.dart';
import 'package:myrecibook/data/sync_source.dart';
import 'package:myrecibook/data/token_store.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/storage_model.dart';

class FakeRemote implements RemoteStore {
  final files = <String, List<int>>{};
  int uploads = 0;
  int deletes = 0;
  int listCalls = 0;
  Object? Function(String name)? failUpload; // non-null return is thrown
  Object? Function(String name)? failDownload;

  @override
  Future<Map<String, RemoteEntry>> list() async {
    listCalls++;
    return {
      for (final e in files.entries)
        e.key: RemoteEntry(
            name: e.key, size: e.value.length, rev: 'r${e.value.length}'),
    };
  }

  @override
  Future<void> upload(String name, List<int> bytes) async {
    final err = failUpload?.call(name);
    if (err != null) throw err;
    uploads++;
    files[name] = List.of(bytes);
  }

  @override
  Future<List<int>> download(String name) async {
    final err = failDownload?.call(name);
    if (err != null) throw err;
    return files[name]!;
  }

  @override
  Future<void> delete(String name) async {
    deletes++;
    files.remove(name);
  }
}

/// SyncSource whose every op reports a lost SAF grant.
class LostSource implements SyncSource {
  @override
  Future<Map<String, SourceEntry>> list() async => throw GrantLostException();

  @override
  Future<List<int>> read(String name) async => throw GrantLostException();

  @override
  Future<void> write(String name, List<int> bytes) async =>
      throw GrantLostException();
}

const idA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const idB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fake-auth-storage-test');
  const codec = StandardMethodCodec();

  late Directory tmp;
  late Directory folder;
  late File settingsFile;
  late File tokensFile;
  late File manifestFile;
  late FakeRemote remote;
  late List<String> launched;
  late int engineBuilds;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_storage_model');
    folder = Directory('${tmp.path}/folder')..createSync();
    settingsFile = File('${tmp.path}/settings.json');
    tokensFile = File('${tmp.path}/tokens.json');
    manifestFile = File('${tmp.path}/manifest.json');
    remote = FakeRemote();
    launched = [];
    engineBuilds = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'launchUrl':
          launched.add(call.arguments as String);
          return null;
        case 'takePendingRedirects':
          return <String>[];
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tmp.delete(recursive: true);
  });

  Future<void> pushRedirect(String uri) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(channel.name,
            codec.encodeMethodCall(MethodCall('onAuthRedirect', uri)), (_) {});
  }

  MockClient tokenClient() => MockClient((req) async => http.Response(
      jsonEncode(
          {'access_token': 'at-1', 'refresh_token': 'rt-1', 'expires_in': 3600}),
      200,
      headers: {'content-type': 'application/json'}));

  Future<StorageModel> makeModel({
    bool configured = true,
    SyncSource? source,
    Duration debounce = const Duration(milliseconds: 40),
  }) async {
    final settings = await AppSettings.load(settingsFile);
    final tokenStore = await TokenStore.load(tokensFile);
    return StorageModel(
      settings: settings,
      tokenStore: tokenStore,
      flow: OAuthFlow(channel: channel, client: tokenClient()),
      driveClientId: configured ? 'gid-1.apps.googleusercontent.com' : 'placeholder-drive',
      dropboxAppKey: configured ? 'appkey-1' : 'placeholder-dropbox',
      remoteFactory: (provider, client) => remote,
      engineFactory: (r, onStatus) {
        engineBuilds++;
        return SyncEngine(
          source: source ?? LocalFolderSource(folder),
          remote: r,
          manifestFile: manifestFile,
          onStatus: onStatus,
        );
      },
      syncDebounce: debounce,
    );
  }

  Future<void> seedConnected() async {
    final settings = await AppSettings.load(settingsFile);
    await settings.setActiveConnector('drive');
    final tokens = await TokenStore.load(tokensFile);
    await tokens.setTokens(
        'drive', const TokenSet(accessToken: 'at-0', refreshToken: 'rt-0'));
  }

  Future<void> put(String rel, String content) async {
    final f = File('${folder.path}/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsString(content);
  }

  Future<void> completeConnect(Future<void> connectCall) async {
    await pumpEventQueue();
    final state = Uri.parse(launched.last).queryParameters['state']!;
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?code=c0de&state=$state');
    await connectCall;
  }

  test('connect happy path: tokens stored, active persisted, initial sync fired',
      () async {
    await put('$idA.json', '{"x":1}');
    final model = await makeModel();
    expect(model.active, isNull);
    expect(model.drawerSummary(folderName: 'recipes'), 'This phone · recipes');
    expect(model.settingsSummary(), 'This phone'); // 6a: alone when local

    await completeConnect(model.connect(StorageModel.drive));

    expect(model.active, 'drive');
    expect(model.connecting, isNull);
    // Persisted through both stores — a fresh load sees the connection.
    expect((await AppSettings.load(settingsFile)).activeConnector, 'drive');
    expect(
        (await TokenStore.load(tokensFile)).tokens('drive')?.accessToken, 'at-1');
    // The initial mirror pass actually ran.
    expect(remote.uploads, 1);
    expect(remote.files.keys, ['$idA.json']);
    expect(model.status.state, SyncState.synced);
    expect(model.remoteFileCount, 1);
    expect(model.drawerSummary(), 'Drive · synced just now');
    expect(model.statusLine(StorageModel.drive),
        'MyReciBook/recipes · 1 file · synced just now');
    expect(model.settingsSummary(),
        'This phone + Google Drive · synced just now');
    model.dispose();
  });

  test('path labels are the remote truth per provider (6e)', () async {
    final model = await makeModel();
    expect(model.pathLabel(StorageModel.drive), 'MyReciBook/recipes');
    expect(model.pathLabel(StorageModel.dropbox), 'Apps/MyReciBook/recipes');
    model.dispose();
  });

  test('placeholder credentials → notConfigured state, browser untouched',
      () async {
    final model = await makeModel(configured: false);
    await model.connect(StorageModel.drive);

    expect(model.notConfigured, 'drive');
    expect(model.active, isNull);
    expect(launched, isEmpty);
    expect(model.drawerSummary(), 'This phone'); // still honestly local
    expect((await AppSettings.load(settingsFile)).activeConnector, isNull);
    model.dispose();
  });

  test('provider error during connect → surfaced per-card, never thrown',
      () async {
    final model = await makeModel();
    final call = model.connect(StorageModel.drive);
    await pumpEventQueue();
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?error=access_denied');
    await call; // must not throw

    expect(model.active, isNull);
    expect(model.connectErrorFor('drive'), contains('access_denied'));
    expect(model.connectErrorFor('dropbox'), isNull);
    model.dispose();
  });

  test('persisted connector restores at construction — no synced claim',
      () async {
    await seedConnected();
    final model = await makeModel();
    expect(model.active, 'drive');
    expect(model.status.state, SyncState.idle);
    expect(model.drawerSummary(), 'Drive'); // nothing synced yet: say nothing
    expect(model.statusLine(StorageModel.drive),
        'MyReciBook/recipes · connected');
    expect(model.settingsSummary(), 'This phone + Google Drive'); // no claim
    model.dispose();
  });

  test('persisted connector with missing tokens → honest reconnect state',
      () async {
    final settings = await AppSettings.load(settingsFile);
    await settings.setActiveConnector('drive'); // tokens never written
    final model = await makeModel();
    expect(model.active, 'drive');
    expect(model.status.state, SyncState.authRevoked);
    expect(model.drawerSummary(), 'Drive · reconnect');
    model.dispose();
  });

  test('disconnect clears tokens + active, remote files stay', () async {
    await seedConnected();
    remote.files['$idA.json'] = [1, 2, 3];
    final model = await makeModel();

    await model.disconnect();

    expect(model.active, isNull);
    expect(model.drawerSummary(), 'This phone');
    expect((await AppSettings.load(settingsFile)).activeConnector, isNull);
    expect((await TokenStore.load(tokensFile)).tokens('drive'), isNull);
    expect(remote.files.keys, ['$idA.json']); // the user's copy — untouched
    expect(remote.deletes, 0);
    model.dispose();
  });

  test('syncSoon debounces: two rapid saves through LibraryModel = one pass',
      () async {
    await seedConnected();
    final model = await makeModel();
    final store = LocalFolderStore(folder);
    final library = LibraryModel(store, onChanged: model.syncSoon);

    Recipe recipe(String id, String title) => Recipe.assemble(
          id: id,
          content: {
            'title': title,
            'ingredients': [
              {'raw': '2 eggs', 'confidence': 0.9},
            ],
            'steps': [
              {'raw': 'Mix.', 'confidence': 0.9},
            ],
          },
          originalImages: const [],
          importedAt: DateTime.utc(2026, 8, 6),
          extractorModel: 'fake',
          extractorMode: 'image',
        );

    await library.saveImported(recipe(idA, 'Soup'), const []);
    await library.saveImported(recipe(idB, 'Stew'), const []);
    expect(engineBuilds, 0); // still inside the debounce window

    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(engineBuilds, 1); // coalesced into one pass
    expect(remote.uploads, 2); // …that carried both files
    expect(model.status.state, SyncState.synced);
    model.dispose();
  });

  test('syncSoon without a connector is a quiet no-op', () async {
    final model = await makeModel();
    model.syncSoon();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(engineBuilds, 0);
    expect(model.status.state, SyncState.idle);
    model.dispose();
  });

  test('auth revoked during sync → reconnect state, never a crash', () async {
    await seedConnected();
    await put('$idA.json', '{"x":1}');
    remote.failUpload = (_) => const AuthRevokedException('revoked');
    final model = await makeModel(debounce: const Duration(milliseconds: 10));

    model.syncSoon();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(model.status.state, SyncState.authRevoked);
    expect(model.drawerSummary(), 'Drive · reconnect');
    expect(model.statusLine(StorageModel.drive),
        'MyReciBook/recipes · reconnect needed');
    expect(model.settingsSummary(), 'This phone + Google Drive · reconnect');
    model.dispose();
  });

  test('offline during sync → offline state, resumes semantics intact',
      () async {
    await seedConnected();
    await put('$idA.json', '{"x":1}');
    remote.failUpload = (_) => SyncIoException('down');
    final model = await makeModel(debounce: const Duration(milliseconds: 10));

    model.syncSoon();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(model.status.state, SyncState.offline);
    expect(model.drawerSummary(), 'Drive · offline');
    model.dispose();
  });

  test('grant lost during sync routes to the re-pick flow', () async {
    await seedConnected();
    var lost = 0;
    final model = await makeModel(
        source: LostSource(), debounce: const Duration(milliseconds: 10));
    model.onGrantLost = () => lost++;

    model.syncSoon();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(lost, 1);
    model.dispose();
  });

  test('restore copies remote files back additively and returns the count',
      () async {
    await seedConnected();
    remote.files['$idA.json'] = utf8.encode('{"a":1}');
    remote.files['images/$idA-1.jpg'] = [9, 9];
    remote.files['$idB.json'] = utf8.encode('{"b":1}');
    await put('$idB.json', 'local wins'); // already present — never overwritten
    final model = await makeModel();

    final n = await model.restore();

    expect(n, 2);
    expect(await File('${folder.path}/$idA.json').readAsString(), '{"a":1}');
    expect(
        await File('${folder.path}/$idB.json').readAsString(), 'local wins');
    expect(model.status.state, SyncState.synced);
    expect(model.remoteFileCount, 3);
    model.dispose();
  });

  test('restore failures rethrow typed for the screen', () async {
    await seedConnected();
    remote.files['$idA.json'] = [1];
    remote.failDownload = (_) => SyncIoException('down');
    final model = await makeModel();

    await expectLater(model.restore(), throwsA(isA<SyncIoException>()));
    expect(model.status.state, SyncState.offline);

    remote.failDownload = (_) => const AuthRevokedException('revoked');
    await expectLater(model.restore(), throwsA(isA<AuthRevokedException>()));
    expect(model.status.state, SyncState.authRevoked);
    model.dispose();
  });

  test('restore without a connector throws SyncIoException', () async {
    final model = await makeModel();
    await expectLater(model.restore(), throwsA(isA<SyncIoException>()));
    model.dispose();
  });

  test('relative formatter: just now / min / hr / days', () {
    final now = DateTime(2026, 8, 6, 12, 0, 0);
    String rel(Duration ago) =>
        StorageModel.relative(now.subtract(ago), now: now);
    expect(rel(const Duration(seconds: 30)), 'just now');
    expect(rel(const Duration(minutes: 2)), '2 min ago');
    expect(rel(const Duration(hours: 3)), '3 hr ago');
    expect(rel(const Duration(days: 1)), '1 day ago');
    expect(rel(const Duration(days: 12)), '12 days ago');
  });
}
