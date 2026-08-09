// Grocery 4a end-to-end: detail add → sections, cross-recipe merge, the
// "Same thing?" prompt, recategorize + check-off persistence across restart
// (new store over the same temp files), manual add, clear checked, empty
// state, receipt banner. Same harness discipline as app_flow_test.dart;
// snackbar asserts use the SHORT settle (rule 8).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/grocery_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/grocery_model.dart';
import 'package:myrecibook/ui/grocery_tab.dart';
import 'package:provider/provider.dart';

import '../helpers/fixtures.dart' show ing;

class FakeExtractor implements Extractor {
  @override
  String get mode => 'image';
  @override
  String get modelName => 'fake-model';
  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      {'title': 'Unused', 'ingredients': <Object?>[], 'steps': <Object?>[], 'extraction': <String, Object?>{}};
}

Map<String, dynamic> content(String title, List<Map<String, dynamic>> ings) =>
    {
      'title': title,
      'ingredients': ings,
      'steps': [
        {'raw': 'Cook.', 'confidence': 0.9}
      ],
      'extraction': {'overall_confidence': 0.9, 'needs_review': <Object?>[]},
    };

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late File pick;
  late File listFile;
  late File overridesFile;
  late GroceryStore grocery;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_grocery_flow');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    pick = File('${tmp.path}/pick1.jpg');
    await pick.writeAsBytes([1, 2, 3]);
    listFile = File('${tmp.path}/grocery_list.json');
    overridesFile = File('${tmp.path}/grocery_overrides.json');
    grocery = await GroceryStore.load(
        listFile: listFile, overridesFile: overridesFile);
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Widget app({GroceryStore? groceryStore}) => buildApp(
      store: store,
      extractor: FakeExtractor(),
      picker: () async => [pick],
      grocery: groceryStore ?? grocery);

  Future<void> seed(
          WidgetTester tester, String id, String title, List<Map<String, dynamic>> ings) =>
      tester.runAsync(() => store.save(
            Recipe.assemble(
              id: id,
              content: content(title, ings),
              originalImages: const [],
              importedAt: DateTime.utc(2026, 8, 6),
              extractorModel: 'fake-model',
              extractorMode: 'image',
            ),
            const [],
          ));

  List<Map<String, dynamic>> pastaIngs() => [
        ing('2 lemons', qty: 2, item: 'lemons'),
        ing('400 g spaghetti', qty: 400, unit: 'g', item: 'spaghetti'),
        ing('olive oil', item: 'olive oil'),
      ];

  // Detail 3e footer button — nav bar also says 'Grocery', so scope to button.
  Finder groceryButton() => find.widgetWithText(FilledButton, 'Grocery');

  Future<void> addFromDetail(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await settle(tester);
    await tester.tap(groceryButton());
    await settle(tester, rounds: 6);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle(tester, rounds: 6);
  }

  // .last = the nav-bar label once the tab's own header also says 'Grocery'.
  Future<void> goGrocery(WidgetTester tester) async {
    await tester.tap(find.text('Grocery').last);
    await settle(tester, rounds: 4);
  }

  testWidgets('empty grocery: honest zero state with the designed header',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await goGrocery(tester);

    expect(find.text('0 items'), findsOneWidget);
    expect(find.byKey(const Key('grocery-add-field')), findsOneWidget);
    expect(find.text('Same thing?'), findsNothing);
  });

  testWidgets('detail add → aisle sections, staple dimming, live caption',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', pastaIngs());
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text('Pasta'));
    await settle(tester);
    await tester.tap(groceryButton());
    await settle(tester, rounds: 6);
    expect(find.text('Added to grocery'), findsOneWidget);
    expect(find.byIcon(Icons.playlist_add_check_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await settle(tester, rounds: 6);
    await goGrocery(tester);

    expect(find.text('3 items · from 1 planned recipe'), findsOneWidget);
    expect(find.text('PRODUCE · 1'), findsOneWidget);
    expect(find.text('PANTRY · 2'), findsOneWidget);
    expect(find.textContaining('lemons', findRichText: true), findsOneWidget);
    expect(find.text('staple'), findsOneWidget);
    expect(find.text('Staples stay quiet unless you tap them.'), findsOneWidget);

    // Staple tap activates — chip and dimming gone, still quantity-less.
    await tester.tap(find.textContaining('olive oil', findRichText: true));
    await settle(tester, rounds: 4);
    expect(find.text('staple'), findsNothing);
    expect(find.text('Staples stay quiet unless you tap them.'), findsNothing);
  });

  testWidgets('same ingredient across two recipes sums into one row',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', [ing('2 lemons', qty: 2, item: 'lemons')]);
    await seed(tester, 'salmon', 'Salmon', [
      ing('4 lemons', qty: 4, item: 'lemons'),
      ing('400 g spinach', qty: 400, unit: 'g', item: 'spinach'),
    ]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await addFromDetail(tester, 'Salmon');
    await goGrocery(tester);

    expect(find.text('6 lemons', findRichText: true), findsOneWidget);
    expect(find.text('2 recipes'), findsOneWidget);
    expect(find.text('PRODUCE · 2'), findsOneWidget);
    expect(find.text('2 items · from 2 planned recipes'), findsOneWidget);
    expect(find.text('Same thing?'), findsNothing); // same key merges silently-as-sum
  });

  testWidgets('near-duplicate raises Same thing?; confirm merges', (tester) async {
    await seed(tester, 'pasta', 'Pasta', [ing('2 lemon', qty: 2, item: 'lemon')]);
    await seed(tester, 'salmon', 'Salmon', [ing('4 lemons', qty: 4, item: 'lemons')]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await addFromDetail(tester, 'Salmon');
    await goGrocery(tester);

    expect(find.text('Same thing?'), findsOneWidget);
    expect(find.text('2 lemon (Pasta) + 4 lemons (Salmon)', findRichText: true),
        findsOneWidget);

    await tester.tap(find.text('Merge · 6 lemons'));
    await settle(tester, rounds: 6);
    expect(find.text('Same thing?'), findsNothing);
    expect(find.text('6 lemons', findRichText: true), findsOneWidget);
    expect(find.text('PRODUCE · 1'), findsOneWidget);
  });

  testWidgets('second tap on the detail button subtracts the recipe',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', pastaIngs());
    await tester.pumpWidget(app());
    await settle(tester);

    await tester.tap(find.text('Pasta'));
    await settle(tester);
    await tester.tap(groceryButton());
    await settle(tester, rounds: 6);
    expect(find.byIcon(Icons.playlist_add_check_rounded), findsOneWidget);

    await tester.tap(groceryButton());
    await settle(tester); // full settle: queued snackbar shows after the first
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
    expect(grocery.items, isEmpty);
  });

  testWidgets('recipe fully covered by checked rows: honest nothing-added copy',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', [ing('2 lemons', qty: 2, item: 'lemons')]);
    await seed(tester, 'water', 'Lemon water', [ing('1 lemon', qty: 1, item: 'lemons')]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);
    await tester.tap(find.textContaining('lemons', findRichText: true));
    await settle(tester, rounds: 4);

    await tester.tap(find.text('Cookbook'));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Lemon water'));
    await settle(tester);
    await tester.tap(groceryButton());
    await settle(tester, rounds: 6);

    // Nothing was added and the recipe is not on the list — never say "Added".
    expect(find.text('Nothing added — everything is already checked off'),
        findsOneWidget);
    expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);
  });

  testWidgets('recategorize: long-press → new aisle, pinned, remembered across restart',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta',
        [ing('2 tbsp sesame oil', qty: 2, unit: 'tbsp', item: 'sesame oil')]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);
    expect(find.text('PANTRY · 1'), findsOneWidget);

    await tester.longPress(find.textContaining('sesame oil', findRichText: true));
    await settle(tester, rounds: 4);
    expect(find.text('MOVE TO'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('new-aisle-field')), 'Asian pantry');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, rounds: 6);

    expect(find.text('ASIAN PANTRY · 1'), findsOneWidget);
    expect(find.text('your aisle'), findsOneWidget);
    expect(find.text('moved here by you'), findsOneWidget);
    expect(find.text('PANTRY · 1'), findsNothing);

    // Restart: new store over the same files — correction and item survive.
    // UI updates before persistence; the write chain (override file + list
    // file, temp+rename each) needs a full settle before reloading from disk.
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final store2 = (await tester.runAsync(() => GroceryStore.load(
        listFile: listFile, overridesFile: overridesFile)))!;
    await tester.pumpWidget(app(groceryStore: store2));
    await settle(tester);
    await goGrocery(tester);

    expect(find.text('ASIAN PANTRY · 1'), findsOneWidget);
    expect(find.text('your aisle'), findsOneWidget);
    expect(find.text('moved here by you'), findsOneWidget);
  });

  testWidgets('check-off persists across restart', (tester) async {
    await seed(tester, 'pasta', 'Pasta', [ing('2 lemons', qty: 2, item: 'lemons')]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);
    await tester.tap(find.textContaining('lemons', findRichText: true));
    await settle(tester, rounds: 4);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Flush the fire-and-forget persist before reloading from disk.
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    final store2 = (await tester.runAsync(() => GroceryStore.load(
        listFile: listFile, overridesFile: overridesFile)))!;
    await tester.pumpWidget(app(groceryStore: store2));
    await settle(tester);
    await goGrocery(tester);

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('manual add lands in its default aisle', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await goGrocery(tester);

    await tester.enterText(find.byKey(const Key('grocery-add-field')), 'capers');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester, rounds: 6);

    expect(find.text('capers', findRichText: true), findsOneWidget);
    expect(find.text('PANTRY · 1'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget); // no planned recipes yet
  });

  testWidgets('Clear checked removes bought rows, keeps the rest',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', pastaIngs());
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);
    await tester.tap(find.textContaining('lemons', findRichText: true));
    await settle(tester, rounds: 4);

    await tester.tap(find.byKey(const Key('grocery-share-button')));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Clear checked'));
    await settle(tester, rounds: 6);

    expect(find.textContaining('lemons', findRichText: true), findsNothing);
    expect(find.text('PRODUCE · 1'), findsNothing);
    expect(find.text('PANTRY · 2'), findsOneWidget);
  });

  testWidgets('swipe removes one row; snackbar Undo restores it',
      (tester) async {
    await seed(tester, 'pasta', 'Pasta', pastaIngs());
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);

    await tester.drag(find.textContaining('lemons', findRichText: true),
        const Offset(-400, 0));
    // SHORT settle (rule 8), but enough rounds for the dismiss slide AND
    // resize (~500ms) to finish and the undo bar to get entrance frames.
    await settle(tester, rounds: 10);
    // The ROW ('2 lemons' with qty) is gone; the undo bar says so.
    expect(find.text('2 lemons', findRichText: true), findsNothing);
    expect(find.text('Removed lemons'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settle(tester, rounds: 4);
    expect(find.text('2 lemons', findRichText: true), findsOneWidget);
    expect(find.text('PRODUCE · 1'), findsOneWidget);
  });

  testWidgets(
      'Clear all: 6f confirm empties the list, Cancel keeps it, '
      'aisle memory survives', (tester) async {
    await seed(tester, 'pasta', 'Pasta', pastaIngs());
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Pasta');
    await goGrocery(tester);

    // Cancel path first: nothing is destroyed without explicit confirm.
    await tester.tap(find.byKey(const Key('grocery-share-button')));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Clear all…'));
    await settle(tester, rounds: 4);
    expect(find.textContaining('remembered'), findsOneWidget); // 6f: survives first
    await tester.tap(find.text('Cancel'));
    await settle(tester, rounds: 4);
    expect(find.textContaining('lemons', findRichText: true), findsOneWidget);

    // Confirm path: list empties back to the honest zero state.
    await tester.tap(find.byKey(const Key('grocery-share-button')));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Clear all…'));
    await settle(tester, rounds: 4);
    await tester.tap(find.text('Clear list'));
    await settle(tester, rounds: 4);
    expect(find.textContaining('lemons', findRichText: true), findsNothing);
    expect(find.byKey(const Key('grocery-add-field')), findsOneWidget);
  });

  testWidgets('receipt banner: re-sync raises it, close dismisses',
      (tester) async {
    await seed(tester, 'salmon', 'Salmon',
        [ing('2 lemons', qty: 2, item: 'lemons')]);
    await tester.pumpWidget(app());
    await settle(tester);

    await addFromDetail(tester, 'Salmon');
    await goGrocery(tester);

    final model = Provider.of<GroceryModel>(
        tester.element(find.byType(GroceryTab)),
        listen: false);
    final bumped = Recipe.assemble(
      id: 'salmon',
      content: content('Salmon', [ing('4 lemons', qty: 4, item: 'lemons')]),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 6),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );
    await tester.runAsync(() => model.syncRecipe(bumped, servings: 4));
    await settle(tester, rounds: 4);

    expect(find.text('Salmon bumped to 4 servings — 1 amount updated.'),
        findsOneWidget);
    expect(find.text('4 lemons', findRichText: true), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await settle(tester, rounds: 2);
    expect(find.textContaining('amount updated'), findsNothing);
  });
}
