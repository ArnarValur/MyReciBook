// Storage screen (promoted 3h) + drawer truthful states: designed copy,
// connect's honest notConfigured state, disconnect, restore confirm → count
// snackbar, reconnect on revoked auth. Model is wired to real temp-dir stores
// with a FakeRemote — same harness discipline as the other UI tests (real IO
// settles via runAsync rounds; snackbar assertions use SHORT settles).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/oauth.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/remote_store.dart';
import 'package:myrecibook/data/sync_engine.dart';
import 'package:myrecibook/data/sync_source.dart';
import 'package:myrecibook/data/token_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/storage_model.dart';
import 'package:myrecibook/ui/storage_screen.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

class FakeRemote implements RemoteStore {
  final files = <String, List<int>>{};

  @override
  Future<Map<String, RemoteEntry>> list() async => {
        for (final e in files.entries)
          e.key: RemoteEntry(name: e.key, size: e.value.length, rev: 'r'),
      };

  @override
  Future<void> upload(String name, List<int> bytes) async =>
      files[name] = List.of(bytes);

  @override
  Future<List<int>> download(String name) async => files[name]!;

  @override
  Future<void> delete(String name) async => files.remove(name);
}

class NoopExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async => {};
}

const idA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

void main() {
  late Directory tmp;
  late Directory folder;
  late FakeRemote remote;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_storage_screen');
    folder = Directory('${tmp.path}/folder')..createSync();
    remote = FakeRemote();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  // Restore runs ~15 real-IO awaits before its snackbar, but a full settle
  // outlives the 4s snackbar (rule 8) — pump until the text lands, assert
  // right away.
  Future<void> settleUntil(WidgetTester tester, Finder f,
      {int max = 40}) async {
    for (var i = 0; i < max; i++) {
      if (f.evaluate().isNotEmpty) return;
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<StorageModel> makeModel(WidgetTester tester,
      {bool connected = false, bool tokensPresent = true}) async {
    return (await tester.runAsync(() async {
      final settings =
          await AppSettings.load(File('${tmp.path}/settings.json'));
      final tokens = await TokenStore.load(File('${tmp.path}/tokens.json'));
      if (connected) {
        await settings.setActiveConnector('drive');
        if (tokensPresent) {
          await tokens.setTokens('drive',
              const TokenSet(accessToken: 'at-0', refreshToken: 'rt-0'));
        }
      }
      return StorageModel(
        settings: settings,
        tokenStore: tokens,
        flow: OAuthFlow(
            channel: const MethodChannel('unused-storage-screen-test')),
        remoteFactory: (provider, client) => remote,
        engineFactory: (r, onStatus) => SyncEngine(
          source: LocalFolderSource(folder),
          remote: r,
          manifestFile: File('${tmp.path}/manifest.json'),
          onStatus: onStatus,
        ),
      );
    }))!;
  }

  Widget screen(StorageModel model,
          {String? folderName,
          VoidCallback? onChangeFolder,
          VoidCallback? onRestored}) =>
      ChangeNotifierProvider<StorageModel>.value(
        value: model,
        child: MaterialApp(
          theme: rbLightTheme(),
          home: StorageScreen(
              folderName: folderName,
              onChangeFolder: onChangeFolder,
              onRestored: onRestored),
        ),
      );

  testWidgets('renders the three designed cards with exact 3h copy',
      (tester) async {
    final model = await makeModel(tester);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model, folderName: 'recipes'));
    await settle(tester, rounds: 4);

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Where should your recipes live?'), findsOneWidget);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('zero setup · works offline'), findsOneWidget);
    expect(find.text('recipes'), findsOneWidget); // current folder on the card
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text("app folder only — we can't see the rest"), findsOneWidget);
    expect(find.text('Dropbox'), findsOneWidget);
    expect(find.text('app folder only'), findsOneWidget);
    expect(find.text('Connect'), findsNWidgets(2));
    // Local selected: the primary check on the This-phone card.
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('WHAT A RECIPE LOOKS LIKE ON DISK'), findsOneWidget);
    expect(find.text('MyReciBook/recipes/creamy-garlic-pasta.json'),
        findsOneWidget);
    expect(find.textContaining('If MyReciBook vanished tomorrow'),
        findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    // Honest: nothing claims sync on a local-only build.
    expect(find.textContaining('synced'), findsNothing);
  });

  testWidgets('placeholder build: Connect surfaces the honest awaiting state',
      (tester) async {
    final model = await makeModel(tester);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Connect').first); // Drive
    await settle(tester, rounds: 4);

    expect(find.text('awaiting keys in this build'), findsOneWidget);
    expect(find.text('Connect'), findsNWidgets(2)); // still connectable later
  });

  testWidgets('connected card: truthful status line, Disconnect and Restore',
      (tester) async {
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    // Connected but nothing synced this session — says 'connected', not
    // 'synced' (the honesty rule is hard).
    expect(find.text('MyReciBook · connected'), findsOneWidget);
    expect(find.text('Disconnect'), findsOneWidget);
    expect(find.text('Restore from Google Drive'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget); // only Dropbox offers it
    expect(find.textContaining('synced'), findsNothing);

    await tester.tap(find.text('Disconnect'));
    await settle(tester, rounds: 4);
    expect(find.text('Connect'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('restore: confirm dialog → count snackbar → library refresh',
      (tester) async {
    remote.files['$idA.json'] = utf8.encode('{"a":1}');
    remote.files['images/$idA-1.jpg'] = [9, 9];
    var refreshed = 0;
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model, onRestored: () => refreshed++));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Restore from Google Drive'));
    await settle(tester, rounds: 4);
    expect(find.text('Restore from Google Drive?'), findsOneWidget);
    expect(find.textContaining('Nothing is overwritten'), findsOneWidget);

    await tester.tap(find.text('Restore'));
    await settleUntil(
        tester, find.text('Restored 2 files from Google Drive'));

    expect(find.text('Restored 2 files from Google Drive'), findsOneWidget);
    expect(refreshed, 1);
    expect(File('${folder.path}/$idA.json').existsSync(), isTrue);
    // The card now proves the pass: count + synced.
    expect(find.text('MyReciBook · 2 files · synced just now'), findsOneWidget);
  });

  testWidgets('restore with nothing missing says so honestly', (tester) async {
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Restore from Google Drive'));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Restore'));
    await settleUntil(tester, find.textContaining('already has everything'));

    expect(find.textContaining('already has everything'), findsOneWidget);
  });

  testWidgets('revoked auth: Reconnect offered, Restore hidden, no crash',
      (tester) async {
    final model =
        await makeModel(tester, connected: true, tokensPresent: false);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    expect(find.text('MyReciBook · reconnect needed'), findsOneWidget);
    expect(find.text('Reconnect'), findsOneWidget);
    expect(find.text('Restore from Google Drive'), findsNothing);
    expect(find.text('Disconnect'), findsOneWidget); // the way out still exists
  });

  testWidgets('drawer storage row tells the truth per state', (tester) async {
    final store = LocalFolderStore(Directory('${tmp.path}/recipes'));

    // Connected + a real synced pass → 'Drive · synced just now'.
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.runAsync(model.restore); // empty remote: legitimate pass
    await tester.pumpWidget(buildApp(
      store: store,
      extractor: NoopExtractor(),
      picker: () async => [],
      storage: model,
      folderName: 'recipes',
    ));
    await settle(tester);

    await tester.tap(find.byKey(const Key('drawer-button')));
    await settle(tester, rounds: 4);
    expect(find.text('Drive · synced just now'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    expect(find.textContaining('This phone ·'), findsNothing);
  });

  testWidgets('drawer storage row shows reconnect when auth is dead',
      (tester) async {
    final store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    final model =
        await makeModel(tester, connected: true, tokensPresent: false);
    addTearDown(model.dispose);
    await tester.pumpWidget(buildApp(
      store: store,
      extractor: NoopExtractor(),
      picker: () async => [],
      storage: model,
      folderName: 'recipes',
    ));
    await settle(tester);

    await tester.tap(find.byKey(const Key('drawer-button')));
    await settle(tester, rounds: 4);
    expect(find.text('Drive · reconnect'), findsOneWidget);
    expect(find.textContaining('synced'), findsNothing);
  });
}
