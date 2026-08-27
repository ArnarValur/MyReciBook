// The "Add food" picker's layout contract, design 2a/2b: a Pantry | Recipes
// tab pair over one search field, and BOTH tabs' shelves opening folded.
//
// The assertion this file exists for is the fold: nothing under a closed
// header may be built. Flat-rendering the pantry is what made the sheet slow
// to open, and "hidden but built" would pass a naive eyeball test while
// costing exactly as much — so the checks here are findsNothing before the
// tap and findsOneWidget after it, never a visibility check.
//
// Stores are in-memory, same stance as diary_flow_test.dart: this file
// proves the SHEET, the on-disk contracts live in the store tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/ui/diary/add_food_sheet.dart';
import 'package:myrecibook/ui/diary/diary_model.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:myrecibook/ui/widgets/product_row.dart';
import 'package:provider/provider.dart';

import '../helpers/fixtures.dart';

Product shelfItem(int n, {List<String> tags = const []}) => Product(
      schemaVersion: 1,
      barcode: '70000000000$n',
      name: 'Shelf item $n',
      source: 'off',
      addedAt: '2026-08-18T10:00:00.000Z',
      nutriments: Nutriments(kcal: 100),
      servings: const [Serving(label: '100 g', grams: 100)],
      defaultServing: 0,
      tags: tags,
    );

class _MemoryPantryStore implements ProductStore {
  final products = <String, Product>{};

  @override
  Future<PantryResult> listAll() async =>
      PantryResult(products.values.toList(), 0);

  @override
  Future<Product?> load(String id) async => products[id];

  @override
  Future<Product> save(Product product) async =>
      products[product.id] = product;

  @override
  Future<Product> update(Product product) => save(product);

  @override
  Future<void> delete(String id) async => products.remove(id);

  @override
  Future<Product> attachImage(Product product, File photo) async => product;

  @override
  Future<Product> removeImage(Product product) async => product;

  @override
  File? imageFile(Product product) => null;
}

class _MemoryDiaryStore implements DiaryStore {
  final days = <String, DiaryDay>{};

  @override
  Future<DiaryDay> load(String date) async =>
      days[date] ?? DiaryDay.empty(date);

  @override
  Future<DiaryDay> save(DiaryDay day) async => days[day.date] = day;

  @override
  Future<List<String>> loggedDates() async => days.keys.toList();

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) =>
      collectRecentEntries(this, days: days, limit: limit);
}

class _StubRecipeStore implements RecipeStore {
  List<Recipe> recipes = const [];

  @override
  Future<StoreResult> listAll() async => StoreResult(recipes, 0);

  @override
  Future<Recipe?> load(String id) async => null;

  @override
  Future<Recipe> save(Recipe recipe, List<File> cachedImages,
          {File? coverImage}) async =>
      recipe;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<File?> imageFile(String ref) async => null;
}

void main() {
  late DiaryModel diary;
  late PantryModel pantry;
  late LibraryModel library;

  // Five recipes across overlapping tags, plus one nobody filed: exactly the
  // shape 2b is drawn for — a recipe may sit under several headings, and
  // Untagged is pinned last.
  const tagged = <String, List<String>>{
    'Pancakes': ['Breakfast'],
    'Waffles': ['Breakfast', 'Desserts'],
    'Omelette': ['Breakfast'],
    'Granola': ['Desserts'],
    'Smoothie': <String>[],
  };

  setUp(() async {
    final pantryStore = _MemoryPantryStore();
    // Two categories plus an uncategorised one, so shelf order and the
    // Other-goes-last rule are both under test.
    for (var n = 1; n <= 3; n++) {
      await pantryStore.save(shelfItem(n, tags: const ['Dairy']));
    }
    for (var n = 4; n <= 5; n++) {
      await pantryStore.save(shelfItem(n, tags: const ['Fruit']));
    }
    await pantryStore.save(shelfItem(6));
    pantry = PantryModel(pantryStore);
    diary = DiaryModel(_MemoryDiaryStore(),
        clock: () => DateTime(2026, 8, 19, 9));
    final recipeStore = _StubRecipeStore()
      ..recipes = [
        for (final entry in tagged.entries)
          cannedRecipe('r-${entry.key}', entry.key)
              .copyWith(tags: entry.value),
      ];
    library = LibraryModel(recipeStore);
    await library.rescan();
  });

  /// Mounts a host screen and opens the sheet on Breakfast. The surface is
  /// tall: the lazy ListView must build both sections, or the order and
  /// expansion assertions would be blind.
  Future<void> openSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryModel>.value(value: diary),
        ChangeNotifierProvider<PantryModel>.value(value: pantry),
        ChangeNotifierProvider<LibraryModel>.value(value: library),
      ],
      child: MaterialApp(
        theme: rbLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () =>
                    showAddFoodSheet(context, meal: 'Breakfast'),
                child: const Text('open picker'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open picker'));
    await tester.pumpAndSettle();
  }

  testWidgets('the pantry shelf opens folded and builds nothing under it',
      (tester) async {
    await openSheet(tester);

    // Every category is on screen at once — that is what the fold buys.
    expect(find.text('YOUR PANTRY'), findsOneWidget);
    for (final label in ['🥛 Dairy', '🍎 Fruit', '🏷️ Other']) {
      expect(find.text(label), findsOneWidget);
    }

    // Not "hidden" — not built. A closed section's builder is never called.
    expect(find.byType(ProductRow), findsNothing);

    await tester.tap(find.text('🥛 Dairy'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductRow), findsNWidgets(3));

    await tester.tap(find.text('🥛 Dairy'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductRow), findsNothing);
  });

  testWidgets('the whole chip row is gone, quick add included',
      (tester) async {
    await openSheet(tester);

    // Scan and "create food" are pantry management and live on the Pantry tab.
    // Quick add is not — its engine is real and stays — but it is parked
    // behind kQuickAddEnabled (Arnar 2026-08-27: he could not tell from the
    // label what it did). This sheet only adds to the meal.
    expect(find.text('Scan'), findsNothing);
    expect(find.text('Create food'), findsNothing);
    expect(find.text('Quick add'), findsNothing);
  });

  testWidgets('the recipes tab shelves by tag, untagged last',
      (tester) async {
    await openSheet(tester);
    await tester.tap(find.text('Recipes'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR RECIPES · BY TAG'), findsOneWidget);
    expect(
        find.text('A recipe logs as one diary line — its numbers come from '
            'its linked ingredients.'),
        findsOneWidget);

    // Every tag on screen — no "show all N" — and Untagged pinned below them.
    final breakfast = tester.getTopLeft(find.text('Breakfast')).dy;
    final desserts = tester.getTopLeft(find.text('Desserts')).dy;
    final untagged = tester.getTopLeft(find.text('Untagged')).dy;
    expect(breakfast, lessThan(untagged));
    expect(desserts, lessThan(untagged));
    expect(find.textContaining('Show all'), findsNothing);

    // Folded, again: no recipe row exists until a header is tapped.
    expect(find.text('Waffles'), findsNothing);
    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    for (final title in ['Pancakes', 'Waffles', 'Omelette']) {
      expect(find.text(title), findsOneWidget);
    }

    // Tags overlap by design: Waffles is under Desserts as well, and both
    // copies are on screen at once.
    await tester.tap(find.text('Desserts'));
    await tester.pumpAndSettle();
    expect(find.text('Waffles'), findsNWidgets(2));
    expect(find.text('Granola'), findsOneWidget);
  });

  testWidgets('search flattens both shelves and counts the other tab',
      (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).first, 'granola');
    await tester.pumpAndSettle();

    // The Pantry tab is still the one showing, and it says so honestly —
    // but the hit on the other tab is counted, never hidden.
    expect(find.text('PANTRY · 0 MATCHES'), findsOneWidget);
    expect(find.text('Recipes · 1'), findsOneWidget);

    await tester.tap(find.text('Recipes · 1'));
    await tester.pumpAndSettle();

    // Flat results: no shelf headers, no unfolding needed.
    expect(find.text('RECIPES · 1 MATCH'), findsOneWidget);
    expect(find.text('Granola'), findsOneWidget);
    expect(find.text('Desserts'), findsNothing);
  });

  testWidgets('a pantry search flattens the categories away', (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField).first, 'Shelf item 2');
    await tester.pumpAndSettle();

    // .text would also hit the query echoed inside the search field.
    expect(find.widgetWithText(ProductRow, 'Shelf item 2'), findsOneWidget);
    expect(find.text('PANTRY · 1 MATCH'), findsOneWidget);
    expect(find.text('🥛 Dairy'), findsNothing);
    expect(find.text('RECENT'), findsNothing);
  });
}
