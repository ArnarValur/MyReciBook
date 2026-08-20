// The "Add food" picker's layout contract: recipes sit ABOVE the pantry as
// a collapsed strip (a real shelf is a long scroll — a section below it is
// a section nobody finds), and search reaches recipes as well as products.
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

Product shelfItem(int n) => Product(
      schemaVersion: 1,
      barcode: '70000000000$n',
      name: 'Shelf item $n',
      source: 'off',
      addedAt: '2026-08-18T10:00:00.000Z',
      nutriments: Nutriments(kcal: 100),
      servings: const [Serving(label: '100 g', grams: 100)],
      defaultServing: 0,
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

  // Five recipes: two more than the collapsed strip's preview of three.
  const titles = ['Pancakes', 'Waffles', 'Omelette', 'Granola', 'Smoothie'];

  setUp(() async {
    final pantryStore = _MemoryPantryStore();
    for (var n = 1; n <= 6; n++) {
      await pantryStore.save(shelfItem(n));
    }
    pantry = PantryModel(pantryStore);
    diary = DiaryModel(_MemoryDiaryStore(),
        clock: () => DateTime(2026, 8, 19, 9));
    final recipeStore = _StubRecipeStore()
      ..recipes = [
        for (final (i, title) in titles.indexed) cannedRecipe('r$i', title),
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

  testWidgets('recipes sit above the pantry as a collapsed strip',
      (tester) async {
    await openSheet(tester);

    // Both sections are drawn — recipes first. SectionLabel uppercases.
    final recipesY = tester.getTopLeft(find.text('YOUR RECIPES')).dy;
    final pantryY = tester.getTopLeft(find.text('YOUR PANTRY')).dy;
    expect(recipesY, lessThan(pantryY));

    // Only the preview shows; the rest hide behind the expander.
    for (final title in ['Pancakes', 'Waffles', 'Omelette']) {
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text('Granola'), findsNothing);
    expect(find.text('Smoothie'), findsNothing);
    expect(find.text('Show all 5'), findsOneWidget);

    // The three doors are still on the sheet.
    for (final chip in ['Scan', 'Create food', 'Quick add']) {
      expect(find.text(chip), findsOneWidget);
    }
  });

  testWidgets('show all expands the strip, show fewer folds it back',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Show all 5'));
    await tester.pumpAndSettle();
    for (final title in titles) {
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text('Show fewer'));
    await tester.pumpAndSettle();
    expect(find.text('Granola'), findsNothing);
    expect(find.text('Show all 5'), findsOneWidget);
  });

  testWidgets('search finds a recipe by name, even past the preview',
      (tester) async {
    await openSheet(tester);
    // Granola is the fourth recipe — collapsed away until searched for.
    expect(find.text('Granola'), findsNothing);

    await tester.enterText(find.byType(TextField), 'granola');
    await tester.pumpAndSettle();

    expect(find.text('RECIPES · 1 MATCH'), findsOneWidget);
    expect(find.text('Granola'), findsOneWidget);
    expect(find.text('PANTRY · 0 MATCHES'), findsOneWidget);
    expect(find.text('Shelf item 1'), findsNothing);

    // The hit is tappable: the recipe log sheet opens on it.
    await tester.tap(find.text('Granola'));
    await tester.pumpAndSettle();
    expect(find.text('How many servings'), findsOneWidget);
  });

  testWidgets('a pantry-only search hides the recipes section',
      (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'Shelf item 2');
    await tester.pumpAndSettle();

    // .text would also hit the query echoed inside the search field.
    expect(find.widgetWithText(ProductRow, 'Shelf item 2'), findsOneWidget);
    expect(find.text('PANTRY · 1 MATCH'), findsOneWidget);
    expect(find.textContaining('RECIPES'), findsNothing);
    expect(find.text('Pancakes'), findsNothing);
  });
}
