// The recipe→diary chain end to end — the safety net for the gap that let a
// real recipe land in Breakfast with no nutrition behind it.
//
// Three locks, in order:
//  1. Domain: pantry-linked ingredients → per-serving nutrition → an entry
//     whose SNAPSHOT carries the numbers, and keeps them after the product
//     is edited (entries never recompute — diary.dart's snapshot rule).
//  2. Screen: the Add-food picker offers the recipe WITH its kcal, and
//     tapping through the log sheet lands an entry with nutrition in the
//     day the store holds.
//  3. The negative that bit: a recipe with NO productRefs logs honestly
//     with no numbers — empty per_serving, no invented zeros in the total,
//     and the sheet says so out loud. A regression in either direction
//     (numbers appearing from nowhere, or vanishing where links exist)
//     trips here.
//
// Stores are in-memory, diary_flow_test's stance: file IO is proven in
// diary_store_test.dart; this file proves the chain.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/domain/recipe_nutrition.dart';
import 'package:myrecibook/ui/diary/diary_model.dart';
import 'package:myrecibook/ui/diary/diary_tab.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

// --- fixtures -------------------------------------------------------------

Product oats({double kcal = 370}) => Product(
      schemaVersion: 1,
      barcode: '7311070003417',
      name: 'Havregryn',
      brand: 'Axa',
      source: 'off',
      addedAt: '2026-08-18T10:00:00.000Z',
      nutriments: Nutriments(kcal: kcal, fat: 7, carbs: 59, protein: 13),
      servings: const [Serving(label: '1 dl', grams: 35)],
      defaultServing: 0,
    );

Product milk() => Product(
      schemaVersion: 1,
      barcode: '7038010000911',
      name: 'Mellommelk',
      brand: 'Tine',
      source: 'off',
      addedAt: '2026-08-18T10:01:00.000Z',
      nutriments: Nutriments(kcal: 50, fat: 1.2, carbs: 4.5, protein: 3.5),
    );

/// Both ingredients linked and resolvable, 2 servings declared:
///   200 g oats           → 740 kcal
///   2 dl milk (×1.03 g/ml density) → 206 g → 103 kcal
/// whole recipe 843 kcal → 421.5 kcal per serving.
Recipe linkedRecipe() => Recipe(
      schemaVersion: 1,
      id: 'r-overnight-oats',
      title: 'Overnight oats',
      source: const RecipeSource(type: 'screenshot'),
      servings: const Servings(amount: 2),
      ingredients: [
        Ingredient(
            raw: '200 g oats',
            qty: 200,
            unit: 'g',
            item: 'oats',
            productRef: oats().id),
        Ingredient(
            raw: '2 dl milk',
            qty: 2,
            unit: 'dl',
            item: 'milk',
            productRef: milk().id),
      ],
      steps: const [RecipeStep(raw: 'Soak overnight.')],
    );

/// The shape that bit: real ingredients, none linked to the pantry.
Recipe unlinkedRecipe({Servings? servings}) => Recipe(
      schemaVersion: 1,
      id: 'r-plain-pancakes',
      title: 'Plain pancakes',
      source: const RecipeSource(type: 'screenshot'),
      servings: servings,
      ingredients: const [
        Ingredient(raw: '3 eggs', qty: 3, item: 'eggs'),
        Ingredient(raw: '2 dl flour', qty: 2, unit: 'dl', item: 'flour'),
      ],
      steps: const [RecipeStep(raw: 'Fry.')],
    );

Map<String, Product> pantryMap(List<Product> products) =>
    {for (final p in products) p.id: p};

// --- in-memory stores (diary_flow_test's fakes, same contracts) -----------

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
  Future<DiaryDay> save(DiaryDay day) async {
    if (day.isEmpty) {
      days.remove(day.date);
    } else {
      days[day.date] = day;
    }
    return day;
  }

  @override
  Future<List<String>> loggedDates() async =>
      days.keys.toList()..sort((a, b) => b.compareTo(a));

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) =>
      collectRecentEntries(this, days: days, limit: limit);
}

class _StubRecipeStore implements RecipeStore {
  List<Recipe> recipes = const [];

  @override
  Future<StoreResult> listAll() async => StoreResult(recipes, 0);

  @override
  Future<Recipe?> load(String id) async {
    for (final r in recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

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
  // =========================================================================
  // 1. Domain chain — no widgets, the arithmetic and the snapshot rule.
  // =========================================================================
  group('domain chain: linked recipe → per-serving → snapshot entry', () {
    test('pantry links compute per-serving nutrition', () {
      final n =
          recipeNutrition(linkedRecipe(), pantryMap([oats(), milk()]));

      expect(n.covered, 2);
      expect(n.ingredientCount, 2);
      expect(n.isComplete, isTrue);
      expect(n.total.kcal, closeTo(843, 0.01)); // 740 + 103
      expect(n.servings, 2);
      expect(n.perServing!.kcal, closeTo(421.5, 0.01));
      expect(n.perServing!.protein, closeTo(16.605, 0.01));
    });

    test('logging builds an entry whose snapshot carries the numbers', () {
      final n =
          recipeNutrition(linkedRecipe(), pantryMap([oats(), milk()]));
      final entry = entryFromRecipe(
          recipe: linkedRecipe(), nutrition: n, quantity: 1.5, id: 'e1');

      expect(entry.source, DiarySources.recipe);
      expect(entry.ref, 'r-overnight-oats');
      expect(entry.servingLabel, 'serving');
      expect(entry.servingGrams, isNull); // a portion has no honest weight
      expect(entry.perServing.kcal, closeTo(421.5, 0.01));
      expect(entry.total.kcal, closeTo(632.25, 0.01)); // 1.5 servings
      expect(entry.total.fat, closeTo(12.354, 0.01));
      expect(entry.total.carbs, closeTo(95.4525, 0.01));
      expect(entry.total.protein, closeTo(24.9075, 0.01));
    });

    test('the snapshot survives a product edit — entries never recompute',
        () {
      final entry = entryFromRecipe(
        recipe: linkedRecipe(),
        nutrition:
            recipeNutrition(linkedRecipe(), pantryMap([oats(), milk()])),
        quantity: 1,
        id: 'e1',
      );
      final day = DiaryDay.empty('2026-08-19').addEntry('Breakfast', entry);

      // The pantry product is corrected AFTER logging: oats drop to
      // 100 kcal/100 g. A fresh calculation moves…
      final edited = pantryMap([oats(kcal: 100), milk()]);
      expect(recipeNutrition(linkedRecipe(), edited).perServing!.kcal,
          closeTo(151.5, 0.01)); // (200 + 103) / 2

      // …but the logged day, read back through its own file format, still
      // says what was true at log time. Nothing here touches a product.
      final reread = DiaryDay.fromJson(
          jsonDecode(jsonEncode(day.toJson())) as Map<String, dynamic>);
      final stored = reread.meal('Breakfast')!.entries.single;
      expect(stored.perServing.kcal, closeTo(421.5, 0.01));
      expect(reread.total.kcal, closeTo(421.5, 0.01));

      // Re-logging from Recent keeps the snapshot too — ref is display-only.
      final again = relog(stored, id: 'e2');
      expect(again.perServing.kcal, closeTo(421.5, 0.01));
    });

    test('no productRefs → the entry honestly carries no numbers', () {
      final n = recipeNutrition(unlinkedRecipe(), pantryMap([oats()]));

      expect(n.isEmpty, isTrue);
      expect(n.covered, 0);
      expect(n.perServing, isNull); // no servings declared either

      final entry = entryFromRecipe(
          recipe: unlinkedRecipe(), nutrition: n, quantity: 1, id: 'e1');
      expect(entry.servingLabel, 'whole recipe');
      expect(entry.perServing.isEmpty, isTrue);
      expect(entry.total.kcal, isNull); // absent, never a fabricated 0
      expect(entry.toJson()['per_serving'], isEmpty);

      // The day total stays honest as well: no kcal key appears.
      final day = DiaryDay.empty('2026-08-19').addEntry('Breakfast', entry);
      expect(day.total.kcal, isNull);
    });

    test('declared servings without links still log empty numbers', () {
      // "Serves 4" gives a serving unit but no coverage — the label reads
      // "serving", the numbers stay absent.
      final recipe = unlinkedRecipe(servings: const Servings(raw: 'Serves 4'));
      final n = recipeNutrition(recipe, pantryMap([oats()]));
      expect(n.servings, 4);
      expect(n.isEmpty, isTrue);

      final entry =
          entryFromRecipe(recipe: recipe, nutrition: n, quantity: 2, id: 'e1');
      expect(entry.servingLabel, 'serving');
      expect(entry.perServing.isEmpty, isTrue);
      expect(entry.total.kcal, isNull);
    });
  });

  // =========================================================================
  // 2. Screen chain — the picker, the log sheet, the day the store holds.
  // =========================================================================
  group('screen chain: picker → log sheet → stored day', () {
    late _MemoryDiaryStore diaryStore;
    late _MemoryPantryStore pantryStore;
    late _StubRecipeStore recipeStore;
    late DiaryModel diary;
    late LibraryModel library;
    final now = DateTime(2026, 8, 19, 9);

    setUp(() async {
      diaryStore = _MemoryDiaryStore();
      pantryStore = _MemoryPantryStore();
      recipeStore = _StubRecipeStore();
      await pantryStore.save(oats());
      await pantryStore.save(milk());
      diary = DiaryModel(diaryStore, clock: () => now);
      library = LibraryModel(recipeStore);
    });

    Future<void> pump(WidgetTester tester) async {
      await library.rescan(); // the shell rescans on boot; tests mirror it
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<DiaryModel>.value(value: diary),
          ChangeNotifierProvider<PantryModel>(
              create: (_) => PantryModel(pantryStore)),
          ChangeNotifierProvider<LibraryModel>.value(value: library),
        ],
        child: MaterialApp(
          theme: rbLightTheme(),
          home: const DiaryTab(),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('linked recipe shows kcal in the picker and logs a snapshot',
        (tester) async {
      recipeStore.recipes = [linkedRecipe()];
      await pump(tester);

      await tester.tap(find.text('Add food').first); // Breakfast
      await tester.pumpAndSettle();
      expect(find.text('Add to breakfast'), findsOneWidget);

      // The recipe is offered, with its honest per-serving estimate:
      // 421.5 rounds to 422, prefixed "~" — pantry links, not a label.
      await tester.ensureVisible(find.text('Overnight oats'));
      await tester.pumpAndSettle();
      expect(find.text('Overnight oats'), findsOneWidget);
      expect(find.text('~422 kcal per serving'), findsOneWidget);

      await tester.tap(find.text('Overnight oats'));
      await tester.pumpAndSettle();

      // The log sheet states its basis and the moving number.
      expect(
          find.textContaining('Estimated from 2 of 2 ingredients'
              ', split over 2 servings'),
          findsOneWidget);
      expect(find.text('422'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add to Breakfast'));
      await tester.pumpAndSettle();
      // Two routes unwind: the log sheet pops, then the picker behind it.
      await tester.pumpAndSettle();
      expect(find.text('Add to breakfast'), findsNothing);

      // The day shows the row…
      expect(find.text('Overnight oats'), findsOneWidget);

      // …and the day the STORE holds carries the snapshot, not a reference.
      final saved = await diaryStore.load('2026-08-19');
      final entry = saved.meal('Breakfast')!.entries.single;
      expect(entry.source, DiarySources.recipe);
      expect(entry.ref, 'r-overnight-oats');
      expect(entry.quantity, 1);
      expect(entry.servingLabel, 'serving');
      expect(entry.servingGrams, isNull);
      expect(entry.perServing.kcal, closeTo(421.5, 0.01));
      expect(entry.perServing.protein, closeTo(16.605, 0.01));
      expect(saved.total.kcal, closeTo(421.5, 0.01));
    });

    testWidgets('unlinked recipe says so in the picker and logs no numbers',
        (tester) async {
      recipeStore.recipes = [unlinkedRecipe()];
      await pump(tester);

      await tester.tap(find.text('Add food').first);
      await tester.pumpAndSettle();

      // The row is offered but promises nothing.
      await tester.ensureVisible(find.text('Plain pancakes'));
      await tester.pumpAndSettle();
      expect(find.text('no linked ingredients yet'), findsOneWidget);

      await tester.tap(find.text('Plain pancakes'));
      await tester.pumpAndSettle();

      // The sheet says out loud what will happen, twice.
      expect(find.textContaining('No ingredients are linked to pantry foods'),
          findsOneWidget);
      expect(
          find.textContaining(
              'This will log as servings with no numbers behind them'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Add to Breakfast'));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // The stored entry exists — the food was eaten — but carries NO
      // nutrition, and the day fabricates none. If numbers ever appear
      // here, someone started inventing them; if the entry stops landing,
      // logging broke. Both are regressions.
      final saved = await diaryStore.load('2026-08-19');
      final entry = saved.meal('Breakfast')!.entries.single;
      expect(entry.name, 'Plain pancakes');
      expect(entry.source, DiarySources.recipe);
      expect(entry.servingLabel, 'whole recipe');
      expect(entry.perServing.isEmpty, isTrue);
      expect(saved.total.kcal, isNull);
    });
  });
}
