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
import 'package:myrecibook/features.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/app_shell.dart';
import 'package:myrecibook/ui/folder_gate.dart';
import 'package:myrecibook/ui/grocery_tab.dart';
import 'package:myrecibook/version.dart';

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
      'extraction': {'overall_confidence': 0.9, 'needs_review': <Object?>[]},
    };

/// Nav slot 2's label follows the flags: Food (Diary + Pantry) → Pantry →
/// Unlock → Queue. Tests tap the one that is actually there.
final String kSlot2Label = kDiaryEnabled
    ? 'Food'
    : kPantryEnabled
        ? 'Pantry'
        : (kUnlockTabEnabled ? 'Unlock' : 'Queue');

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

  Widget app({ShareEntry? share, Extractor Function(String url)? linkExtractor}) =>
      buildApp(
          store: store,
          extractor: FakeExtractor([canned()]),
          picker: () async => [pick],
          share: share,
          linkExtractor: linkExtractor);

  // .first: the shell's own tab stack. The Food tab nests a second
  // IndexedStack for its Diary/Pantry segments.
  int? stackIndex(WidgetTester tester) =>
      tester.widget<IndexedStack>(find.byType(IndexedStack).first).index;

  testWidgets('nav bar switches tabs; cookbook survives offstage',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    expect(stackIndex(tester), 0);

    await tester.tap(find.text('Grocery'));
    await tester.pump();
    expect(stackIndex(tester), 1);
    expect(find.byType(GroceryTab), findsOneWidget);

    // Slot 2 is Unlock since 2026-08-15 (the queue tab retired — Arnar's
    // call; the queue lives on as the pushed batch route + Cookbook strip),
    // unless the pantry PoC borrows the slot on dev builds (kPantryEnabled,
    // 2026-08-17). Assert whichever surface the flags actually put there.
    await tester.tap(find.text(kSlot2Label));
    await tester.pump();
    expect(stackIndex(tester), 2);
    if (kDiaryEnabled) {
      // Slot 2 opens on the diary; the pantry is behind the segmented pill.
      expect(find.text('Diary'), findsWidgets);
      expect(find.text('BREAKFAST'), findsOneWidget); // SectionLabel uppercases
      await tester.tap(find.text('Pantry').last);
      await tester.pumpAndSettle();
      expect(find.text('Scan a product'), findsOneWidget);
    } else if (kPantryEnabled) {
      expect(find.text('Pantry'), findsWidgets);
      expect(find.text('Scan a product'), findsOneWidget);
    } else {
      // The purchase CTA states its own missing engine instead of no-opping.
      expect(find.text('No subscription. No account. Ever.'), findsOneWidget);
      expect(find.text('ONE-TIME'), findsOneWidget);
      // Constraint 2: the fair-use cap is stated where the money is.
      expect(find.text('600 AI rescues a year — fair-use cap, in writing'),
          findsOneWidget);
      final cta = tester.widget<FilledButton>(find.widgetWithText(
          FilledButton, 'Unlock MyReciBook — \$24.99'));
      expect(cta.onPressed, isNull);
      expect(find.textContaining('nothing to buy just yet'), findsOneWidget);
      // Spread-the-word waits for a live destination (kSpreadWordEnabled).
      expect(find.text('Rate MyReciBook'), findsNothing);
      expect(find.text('Share with a friend'), findsNothing);
    }

    await tester.tap(find.text('Settings'));
    await tester.pump();
    expect(stackIndex(tester), 3);
    expect(find.text('THEME'), findsOneWidget); // real 6a settings surface

    await tester.tap(find.text('Cookbook'));
    await tester.pump();
    expect(stackIndex(tester), 0);
    expect(find.textContaining('Your book is empty'), findsOneWidget);
  });

  testWidgets('no drawer: bar + Settings carry everything, honestly',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    // The drawer was REMOVED 2026-08-06 (founder decision): after the
    // dead-end rule hid its engine-less rows, everything left duplicated the
    // bar or Settings. No menu button, no drawer widget.
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byType(Drawer), findsNothing);

    // Settings owns utility now: truthful storage row + version footer.
    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 4);
    expect(find.text('Where your recipes live'), findsOneWidget);
    // 6a footer rule: version only — no ownership claim without a receipt.
    expect(find.text('MyReciBook $kAppVersion'), findsOneWidget);
    expect(find.textContaining('you own this copy'), findsNothing);
    // Honest state: local-only alpha never claims sync.
    expect(find.textContaining('synced'), findsNothing);
    expect(find.text('This phone'), findsOneWidget);
    // Hidden engines stay hidden (dead-end rule).
    expect(find.text('Meal plan'), findsNothing);
    expect(find.text('Your copy'), findsNothing);
  });

  testWidgets('FAB opens the import sheet from any tab', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text(kSlot2Label));
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

  testWidgets('shared link lands in review with the link source row',
      (tester) async {
    const url = 'https://example.com/best-buns';
    final share = ShareEntry();
    // Canned link content the way LinkExtractor stamps it: source.url set,
    // no images anywhere.
    final linkContent = canned(title: 'Best Buns')
      ..['source'] = {'type': 'link', 'url': url, 'app_hint': 'example.com'};
    await tester.pumpWidget(app(
        share: share,
        linkExtractor: (u) {
          expect(u, url);
          return FakeExtractor([linkContent]);
        }));
    await settle(tester);

    share.pushLink(url);
    await settle(tester);

    expect(find.text('Recipe rescued'), findsOneWidget);
    expect(find.text('Best Buns'), findsOneWidget);
    expect(find.text('From a link'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);
    // No screenshot row for a link import.
    expect(find.text('Original screenshot'), findsNothing);
  });

  testWidgets(
      'Settings storage row shows the real folder and reaches re-pick '
      'through the storage screen', (tester) async {
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
      appBuilder: (safStore, pantry, onGrantLost, onChangeFolder) => buildApp(
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

    await tester.tap(find.text('Settings'));
    await settle(tester, rounds: 4);
    expect(find.text('This phone'), findsOneWidget);

    // The row routes to the 6e storage screen, not straight to the picker.
    await tester.tap(find.text('Where your recipes live'));
    await settle(tester, rounds: 6);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
    // Current folder + real library count on the This-phone card.
    expect(find.text('root-id · 0 recipes'), findsOneWidget);

    // 'Change folder' opens the system picker DIRECTLY — no gate screen in
    // between (Arnar's UX call, 2026-08-06). Re-picking the SAME folder
    // keeps the user right where they were: still on Storage, no gate flash.
    await tester.tap(find.text('Change folder'));
    await settle(tester, rounds: 6);
    expect(find.text('Where should your recipes live?'), findsNothing);
    expect(find.textContaining('access was lost'), findsNothing);
    await settle(tester);
    expect(find.text('Plain files, one per recipe. Yours.'), findsOneWidget);
  });
}
