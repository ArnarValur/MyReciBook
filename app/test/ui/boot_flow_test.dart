// Boot flow: folder gate (pick / re-pick), local→SAF migration smoke, and
// share-sheet intake into the import flow. Same harness discipline as
// app_flow_test.dart — real IO settles via runAsync rounds, the SAF side is
// the in-memory fake channel (no platform calls).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/share_entry.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/app_shell.dart';
import 'package:myrecibook/ui/folder_gate.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/recipe_list_screen.dart';
import 'package:provider/provider.dart';

import '../data/fake_saf_channel.dart';

class FakeExtractor implements Extractor {
  FakeExtractor(this.outcomes);

  /// Consumed in order; last one repeats. Map = success, exception = throw.
  final List<Object> outcomes;
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    final o = outcomes[calls < outcomes.length ? calls : outcomes.length - 1];
    calls++;
    if (o is ExtractionException) throw o;
    // Deep copy — the review screen mutates the content map.
    return jsonDecode(jsonEncode(o)) as Map<String, dynamic>;
  }
}

Map<String, dynamic> canned({String title = 'Pancakes'}) => {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs', 'confidence': 0.95},
        {'raw': '1 cup flour', 'confidence': 0.6},
      ],
      'steps': [
        {'raw': 'Mix everything.', 'confidence': 0.9},
        {'raw': 'Fry until golden.', 'confidence': 0.9},
      ],
      'extraction': {'overall_confidence': 0.9, 'needs_review': []},
    };

Recipe cannedRecipe(String id, String title) => Recipe.assemble(
      id: id,
      content: canned(title: title),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 6),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );

void main() {
  late Directory tmp;
  late FakeSafChannel fake;
  late LocalFolderStore localStore;
  late File settingsFile;
  late File pick;
  late File pick2;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_boot_test');
    fake = FakeSafChannel()..install();
    localStore = LocalFolderStore(Directory('${tmp.path}/recipes'));
    settingsFile = File('${tmp.path}/settings.json');
    pick = File('${tmp.path}/pick1.jpg');
    await pick.writeAsBytes([1, 2, 3]);
    pick2 = File('${tmp.path}/pick2.jpg');
    await pick2.writeAsBytes([4, 5, 6]);
  });

  tearDown(() async {
    fake.uninstall();
    await tmp.delete(recursive: true);
  });

  // Same rhythm as app_flow_test: each round completes roughly one real-IO
  // await (settings writes, local reads) and pumps the fake clock past
  // animations. Fake-channel calls settle as microtasks within the pumps.
  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Future<AppSettings> loadSettings(WidgetTester tester) async =>
      (await tester.runAsync(() => AppSettings.load(settingsFile)))!;

  Widget boot(AppSettings settings, {ShareEntry? share, Extractor? extractor}) {
    // The app's own navigator key, handed to the gate for ready-phase
    // dialogs (change-folder confirm), as main.dart wires it.
    final nav = GlobalKey<NavigatorState>();
    return BootGate(
      settings: settings,
      localStore: localStore,
      imageCache: Directory('${tmp.path}/saf_images'),
      safChannel: fake.channel,
      appNavigatorKey: nav,
      appBuilder: (store, onGrantLost, onChangeFolder) => buildApp(
        store: store,
        extractor: extractor ?? FakeExtractor([canned()]),
        picker: () async => [pick],
        share: share,
        onGrantLost: onGrantLost,
        onChangeFolder: onChangeFolder,
        folderName: folderDisplayName(settings.treeUri),
        navigatorKey: nav,
      ),
    );
  }

  void seedSafRecipe(String id, String title) {
    fake.seedFile(
      '$id.json',
      utf8.encode(const JsonEncoder.withIndent('  ')
          .convert(cannedRecipe(id, title).toJson())),
      mime: 'application/json',
    );
  }

  testWidgets('first run: gate shows, pick enters the app, uri persisted',
      (tester) async {
    final settings = await loadSettings(tester);
    await tester.pumpWidget(boot(settings));
    await settle(tester);

    expect(find.text('Where should your recipes live?'), findsOneWidget);
    expect(find.byType(RecipeListScreen), findsNothing);

    await tester.tap(find.byKey(const Key('choose-folder-button')));
    await settle(tester);

    expect(find.textContaining('Your book is empty'), findsOneWidget);
    expect(settings.treeUri, fake.treeUri);
    expect(settings.migrationDone, isTrue); // empty pass still sets the flag
  });

  testWidgets('grant lost at boot: re-pick copy, picking again recovers',
      (tester) async {
    await tester.runAsync(() => settingsFile.writeAsString(jsonEncode(
        {'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings = await loadSettings(tester);
    seedSafRecipe('seed-1', 'Soup');
    fake.revoked = true;

    await tester.pumpWidget(boot(settings));
    await settle(tester);

    expect(find.text('Pick your folder again'), findsOneWidget);
    expect(find.textContaining('access was lost'), findsOneWidget);

    fake.revoked = false;
    await tester.tap(find.byKey(const Key('choose-folder-button')));
    await settle(tester);

    expect(find.text('Soup'), findsOneWidget);
  });

  testWidgets('grant lost mid-session: rescan swaps back to the gate',
      (tester) async {
    await tester.runAsync(() => settingsFile.writeAsString(jsonEncode(
        {'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings = await loadSettings(tester);
    seedSafRecipe('seed-1', 'Soup');

    await tester.pumpWidget(boot(settings));
    await settle(tester);
    expect(find.text('Soup'), findsOneWidget);

    fake.revoked = true;
    final model = tester
        .element(find.byType(RecipeListScreen))
        .read<LibraryModel>();
    model.rescan(); // what pull-to-refresh runs
    await settle(tester);

    expect(find.text('Pick your folder again'), findsOneWidget);
  });

  testWidgets('grant lost mid-save: review survives with edits, retry saves',
      (tester) async {
    await tester.runAsync(() => settingsFile.writeAsString(jsonEncode(
        {'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings = await loadSettings(tester);

    await tester.pumpWidget(boot(settings));
    await settle(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.byKey(const Key('import-screenshots-tile')));
    await settle(tester);
    expect(find.text('Recipe rescued'), findsOneWidget);

    fake.revoked = true;
    await tester.tap(find.text('Save to cookbook'));
    // Short settle keeps the 4s snackbar alive for the assertion.
    await settle(tester, rounds: 6);

    // No gate swap mid-import — the extraction and edits stay on screen.
    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Pick your folder again'), findsNothing);
    expect(find.textContaining('Folder access was lost'), findsOneWidget);

    fake.revoked = false;
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);
    expect(find.text('Pancakes'), findsOneWidget); // saved on retry
  });

  testWidgets('change folder: backing out of the picker returns to the app',
      (tester) async {
    await tester.runAsync(() => settingsFile.writeAsString(jsonEncode(
        {'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings = await loadSettings(tester);
    seedSafRecipe('seed-1', 'Soup');

    await tester.pumpWidget(boot(settings));
    await settle(tester);
    expect(find.text('Soup'), findsOneWidget);

    // Deliberate change (Storage screen plumbing) goes STRAIGHT to the
    // system picker — no gate interstitial (Arnar's UX call, 2026-08-06).
    // Backing out of the picker is the "keep current folder" path now.
    fake.cancelNextPick = true;
    tester.widget<AppShell>(find.byType(AppShell)).onChangeFolder!();
    await settle(tester, rounds: 4);
    expect(find.text('Where should your recipes live?'), findsNothing);
    expect(find.text('Soup'), findsOneWidget);
  });

  testWidgets('change to a different folder asks first; cancel keeps the library',
      (tester) async {
    await tester.runAsync(() => settingsFile.writeAsString(jsonEncode(
        {'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings = await loadSettings(tester);
    seedSafRecipe('seed-1', 'Soup');
    // The fake serves one tree regardless of uri — the switch is asserted on
    // phase + persisted uri, not on differing folder contents.
    const otherUri = 'content://fake.saf/tree/other-root';

    await tester.pumpWidget(boot(settings));
    await settle(tester);
    expect(find.text('Soup'), findsOneWidget);

    // Picker opens directly off the change call; the confirm dialog rises
    // over the RUNNING app (shared navigator key — no gate behind it).
    fake.nextPickUri = otherUri;
    tester.widget<AppShell>(find.byType(AppShell)).onChangeFolder!();
    await settle(tester, rounds: 4);
    expect(find.text('Switch to this folder?'), findsOneWidget);
    expect(find.text('Soup'), findsOneWidget); // app still up behind it

    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('Soup'), findsOneWidget); // nothing switched
    expect(settings.treeUri, fake.treeUri);

    // Confirmed switch enters the new (empty) folder.
    fake.nextPickUri = otherUri;
    tester.widget<AppShell>(find.byType(AppShell)).onChangeFolder!();
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Switch folder'));
    await settle(tester);
    expect(find.text('Where should your recipes live?'), findsNothing);
    expect(find.byType(RecipeListScreen), findsOneWidget);
    expect(settings.treeUri, otherUri);
  });

  testWidgets('migration smoke: local recipes appear in the SAF-backed list',
      (tester) async {
    await tester.runAsync(() async {
      await localStore.save(cannedRecipe('seed-1', 'Soup'), const []);
      await localStore.save(cannedRecipe('seed-2', 'Stew'), const []);
    });
    final settings = await loadSettings(tester);

    await tester.pumpWidget(boot(settings));
    await settle(tester);
    await tester.tap(find.byKey(const Key('choose-folder-button')));
    await settle(tester);

    expect(find.text('Soup'), findsOneWidget);
    expect(find.text('Stew'), findsOneWidget);
    expect(fake.find('seed-1.json'), isNotNull);
    expect(fake.find('seed-2.json'), isNotNull);
    expect(settings.migrationDone, isTrue);
  });

  testWidgets('warm share opens review with both screenshots', (tester) async {
    final share = ShareEntry();
    await tester.pumpWidget(buildApp(
      store: localStore,
      extractor: FakeExtractor([canned()]),
      picker: () async => [pick],
      share: share,
    ));
    await settle(tester);

    share.push([pick, pick2]);
    await settle(tester);

    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Original screenshots · 2'), findsOneWidget);
  });

  testWidgets('share during open review: queued + snackbar, opens after',
      (tester) async {
    final share = ShareEntry();
    await tester.pumpWidget(buildApp(
      store: localStore,
      extractor: FakeExtractor([canned()]),
      picker: () async => [pick],
      share: share,
    ));
    await settle(tester);

    // Open a review the normal way (FAB → screenshots tile).
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester);
    await tester.tap(find.byKey(const Key('import-screenshots-tile')));
    await settle(tester);
    expect(find.text('Recipe rescued'), findsOneWidget);

    share.push([pick2]);
    // Short settle keeps the 4s snackbar alive for the assertion.
    await settle(tester, rounds: 6);
    expect(find.text('Screenshot saved for your next import'), findsOneWidget);
    expect(find.text('Recipe rescued'), findsOneWidget); // not hijacked

    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    // The queued share re-enters the flow on its own.
    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Original screenshot'), findsOneWidget);
  });

  testWidgets('share before the gate resolves is held, then imports',
      (tester) async {
    final settings = await loadSettings(tester);
    final share = ShareEntry();
    share.push([pick]); // arrived while the gate is still up

    await tester.pumpWidget(boot(settings, share: share));
    await settle(tester);
    expect(find.text('Where should your recipes live?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('choose-folder-button')));
    await settle(tester);

    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Original screenshot'), findsOneWidget);
  });
}
