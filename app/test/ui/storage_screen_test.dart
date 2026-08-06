// Storage screen (6e, turn 6) + drawer truthful states: designed card copy,
// the dimmed awaiting-keys placeholder state, connect on configured builds,
// the 6f disconnect dialog (cancel = no-op, confirm disconnects, remote
// untouched), restore confirm → count snackbar, reconnect on revoked auth.
// Model is wired to real temp-dir stores with a FakeRemote — same harness
// discipline as the other UI tests (real IO settles via runAsync rounds;
// snackbar assertions use SHORT settles).

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
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/library_model.dart';
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
  late LibraryModel library;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_storage_screen');
    folder = Directory('${tmp.path}/folder')..createSync();
    remote = FakeRemote();
    library = LibraryModel(LocalFolderStore(Directory('${tmp.path}/recipes')));
  });

  tearDown(() async {
    library.dispose();
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
      {bool connected = false,
      bool tokensPresent = true,
      bool configured = false}) async {
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
        driveClientId:
            configured ? 'gid-1.apps.googleusercontent.com' : 'placeholder-drive',
        dropboxAppKey: configured ? 'appkey-1' : 'placeholder-dropbox',
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

  Future<void> seedRecipe(WidgetTester tester) async {
    await tester.runAsync(() async {
      await LocalFolderStore(Directory('${tmp.path}/recipes')).save(
        Recipe.assemble(
          id: idA,
          content: {
            'title': 'Soup',
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
        ),
        const [],
      );
      await library.rescan();
    });
  }

  Widget screen(StorageModel model,
          {String? folderName,
          VoidCallback? onChangeFolder,
          VoidCallback? onRestored}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<StorageModel>.value(value: model),
          ChangeNotifierProvider<LibraryModel>.value(value: library),
        ],
        child: MaterialApp(
          theme: rbLightTheme(),
          home: StorageScreen(
              folderName: folderName,
              onChangeFolder: onChangeFolder,
              onRestored: onRestored),
        ),
      );

  testWidgets('6e cards render the designed copy; placeholder creds dim '
      'the providers to the awaiting-keys state', (tester) async {
    await seedRecipe(tester);
    final model = await makeModel(tester);
    addTearDown(model.dispose);
    await tester.pumpWidget(
        screen(model, folderName: 'recipes', onChangeFolder: () {}));
    await settle(tester, rounds: 4);

    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
    // Card 1: real folder name + real LibraryModel count.
    expect(find.text('This phone'), findsOneWidget);
    expect(find.text('recipes · 1 recipe'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Change folder'),
        findsOneWidget);
    // Provider cards, dimmed honest placeholder state — no Connect offered.
    expect(find.text('Google Drive'), findsOneWidget);
    expect(find.text('Dropbox'), findsOneWidget);
    expect(find.text('awaiting keys in this build'), findsNWidgets(2));
    expect(find.text('Connect'), findsNothing);
    expect(
        tester
            .widget<Opacity>(find
                .ancestor(of: find.text('Dropbox'), matching: find.byType(Opacity))
                .first)
            .opacity,
        0.55);
    // The dashed leave-anytime promise.
    expect(find.textContaining('If MyReciBook vanished tomorrow'),
        findsOneWidget);
    // 3h setup furniture is gone (6e supersedes the post-setup presentation).
    expect(find.text('Where should your recipes live?'), findsNothing);
    expect(find.text('Continue'), findsNothing);
    // Honest: nothing claims sync on a local-only build.
    expect(find.textContaining('synced'), findsNothing);
  });

  testWidgets('configured build: unconnected providers wake to Connect',
      (tester) async {
    final model = await makeModel(tester, configured: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    expect(find.text('Connect'), findsNWidgets(2));
    expect(find.text('awaiting keys in this build'), findsNothing);
    expect(find.byType(Opacity), findsNothing); // nothing dimmed
  });

  testWidgets('connected card: true path caption, Restore and Disconnect',
      (tester) async {
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    // Connected but nothing synced this session — says 'connected', not
    // 'synced' (the honesty rule is hard); path label is the remote truth.
    expect(find.text('MyReciBook/recipes · connected'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Restore from Google Drive'),
        findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Disconnect'), findsOneWidget);
    expect(find.textContaining('synced'), findsNothing);
    // Dropbox stays the dimmed placeholder card alongside.
    expect(find.text('awaiting keys in this build'), findsOneWidget);
  });

  testWidgets('disconnect: 6f dialog with the designed copy; cancel is a '
      'no-op', (tester) async {
    remote.files['$idA.json'] = utf8.encode('{"a":1}');
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Disconnect'));
    await settle(tester, rounds: 4);
    expect(find.text('Disconnect Google Drive?'), findsOneWidget);
    // Survives-before-stops, verbatim.
    expect(
        find.text('Nothing is deleted. Your recipes stay in your Drive '
            'folder and in the copy on this phone — they just stop syncing.'),
        findsOneWidget);
    // The confirm repeats the verb on a filled destructive button.
    expect(find.widgetWithText(FilledButton, 'Disconnect'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await settle(tester, rounds: 4);
    expect(model.active, 'drive'); // nothing happened
    expect(find.text('MyReciBook/recipes · connected'), findsOneWidget);
    expect(remote.files.keys, ['$idA.json']);
  });

  testWidgets('disconnect: confirm disconnects; remote files stay untouched',
      (tester) async {
    remote.files['$idA.json'] = utf8.encode('{"a":1}');
    final model = await makeModel(tester, connected: true);
    addTearDown(model.dispose);
    await tester.pumpWidget(screen(model));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Disconnect'));
    await settle(tester, rounds: 4);
    await tester.tap(find.widgetWithText(FilledButton, 'Disconnect'));
    await settle(tester, rounds: 4);

    expect(model.active, isNull);
    // Placeholder creds → both providers fall back to the dimmed state.
    expect(find.text('awaiting keys in this build'), findsNWidgets(2));
    expect(remote.files.keys, ['$idA.json']); // the user's copy — untouched
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
    expect(find.text('MyReciBook/recipes · 2 files · synced just now'),
        findsOneWidget);
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

    expect(find.text('MyReciBook/recipes · reconnect needed'), findsOneWidget);
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
