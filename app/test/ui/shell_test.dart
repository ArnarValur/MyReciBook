// Shell promotion: tab switching, the 5c drawer's designed rows with honest
// state, FAB-import from any tab, share-into-import while on another tab, and
// the drawer Storage row's real folder + re-pick route. Same harness
// discipline as app_flow_test.dart (real IO settles via runAsync rounds).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/share_entry.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/app_shell.dart';
import 'package:myrecibook/ui/folder_gate.dart';
import 'package:myrecibook/ui/grocery_tab.dart';

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
      ],
      'steps': [
        {'raw': 'Mix everything.', 'confidence': 0.9},
      ],
      'extraction': {'overall_confidence': 0.9, 'needs_review': []},
    };

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late File pick;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_shell_test');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    pick = File('${tmp.path}/pick1.jpg');
    await pick.writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Widget app({ShareEntry? share}) => buildApp(
      store: store,
      extractor: FakeExtractor([canned()]),
      picker: () async => [pick],
      share: share);

  int? stackIndex(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack)).index;

  testWidgets('nav bar switches tabs; cookbook survives offstage',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    expect(stackIndex(tester), 0);

    await tester.tap(find.text('Grocery'));
    await tester.pump();
    expect(stackIndex(tester), 1);
    expect(find.byType(GroceryTab), findsOneWidget);

    await tester.tap(find.text('Plan'));
    await tester.pump();
    expect(stackIndex(tester), 2);
    expect(find.text('Meal planning lands post-alpha.'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(stackIndex(tester), 3);
    expect(find.text('Settings land post-alpha.'), findsOneWidget);

    await tester.tap(find.text('Cookbook'));
    await tester.pump();
    expect(stackIndex(tester), 0);
    expect(find.textContaining('Your book is empty'), findsOneWidget);
  });

  testWidgets('drawer: designed rows, honest state, row switches tab',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.byKey(const Key('drawer-button')));
    await settle(tester, rounds: 4);

    expect(find.text('Meal plan'), findsOneWidget);
    expect(find.text('Import queue'), findsOneWidget);
    expect(find.text('Your copy'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Help & feedback'), findsOneWidget);
    expect(find.text('MyReciBook 1.0 · you own this copy'), findsOneWidget);
    // Honest state: local-only alpha never claims sync; no fake queue badge.
    expect(find.textContaining('synced'), findsNothing);
    expect(find.text('This phone'), findsOneWidget);

    await tester.tap(find.text('Meal plan'));
    await settle(tester, rounds: 4);
    expect(stackIndex(tester), 2);
    expect(find.text('Import queue'), findsNothing); // drawer closed
  });

  testWidgets('FAB opens the import sheet from any tab', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text('Plan'));
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 4);

    expect(find.text('Add to your book'), findsOneWidget);
  });

  testWidgets('share lands in review while on another tab', (tester) async {
    final share = ShareEntry();
    await tester.pumpWidget(app(share: share));
    await settle(tester);

    await tester.tap(find.text('Grocery'));
    await tester.pump();

    share.push([pick]);
    await settle(tester);
    expect(find.text('Recipe rescued'), findsOneWidget);
  });

  testWidgets('drawer storage row shows the real folder and reaches re-pick',
      (tester) async {
    final fake = FakeSafChannel()..install();
    addTearDown(fake.uninstall);
    final settingsFile = File('${tmp.path}/settings.json');
    await tester.runAsync(() => settingsFile.writeAsString(
        jsonEncode({'tree_uri': fake.treeUri, 'migration_done': true})));
    final settings =
        (await tester.runAsync(() => AppSettings.load(settingsFile)))!;

    await tester.pumpWidget(BootGate(
      settings: settings,
      localStore: store,
      imageCache: Directory('${tmp.path}/saf_images'),
      safChannel: fake.channel,
      appBuilder: (safStore, onGrantLost, onChangeFolder) => buildApp(
        store: safStore,
        extractor: FakeExtractor([canned()]),
        picker: () async => [pick],
        onGrantLost: onGrantLost,
        onChangeFolder: onChangeFolder,
        folderName: folderDisplayName(settings.treeUri),
      ),
    ));
    await settle(tester);
    expect(find.textContaining('Your book is empty'), findsOneWidget);

    await tester.tap(find.byKey(const Key('drawer-button')));
    await settle(tester, rounds: 4);
    expect(find.text('This phone · root-id'), findsOneWidget);

    await tester.tap(find.text('Storage'));
    await settle(tester);
    // Deliberate change-folder: first-run copy, never the "lost" copy.
    expect(find.text('Where should your recipes live?'), findsOneWidget);
    expect(find.textContaining('access was lost'), findsNothing);

    // Picking again returns to the app intact.
    await tester.tap(find.byKey(const Key('choose-folder-button')));
    await settle(tester);
    expect(find.textContaining('Your book is empty'), findsOneWidget);
  });
}
