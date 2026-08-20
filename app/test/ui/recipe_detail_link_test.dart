// Linked ingredient rows on the detail screen (Arnar 2026-08-20): a
// pantry-linked row shows qty + unit + the PRODUCT's name inline as the
// ingredient name — one line, no sub-line. Display-time substitution only:
// the recipe file's raw text is never touched, so unlink and re-import stay
// clean. Unlinked rows render exactly as before. Same real-IO settle harness
// as app_flow_test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/domain/units.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/recipe_detail_screen.dart';
import 'package:myrecibook/ui/units_model.dart';

class NoCallExtractor implements Extractor {
  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async =>
      throw StateError('detail rendering must never extract');
}

void main() {
  group('linkedIngredientLine — the substitution rule', () {
    test('item found in raw: replaced in place, typed text around survives', () {
      const ing = Ingredient(
          raw: '2 dl milk, warm', qty: 2, unit: 'dl', item: 'milk');
      expect(linkedIngredientLine(ing, 'Mellommelk 2,0% fett'),
          '2 dl Mellommelk 2,0% fett, warm');
    });

    test('item match is case-insensitive', () {
      const ing = Ingredient(raw: '1 cup Flour', item: 'flour');
      expect(linkedIngredientLine(ing, 'Hvetemel Extra'),
          '1 cup Hvetemel Extra');
    });

    test('no item in raw but qty parsed: rebuilt as qty unit name', () {
      const ing = Ingredient(raw: 'melk — 2 dl', qty: 2, unit: 'dl');
      expect(linkedIngredientLine(ing, 'Mellommelk 2,0% fett'),
          '2 dl Mellommelk 2,0% fett');
    });

    test('qty without unit, whole and decimal formatting', () {
      const eggs = Ingredient(raw: 'egg x2', qty: 2);
      expect(linkedIngredientLine(eggs, 'Frokostegg'), '2 Frokostegg');
      const half = Ingredient(raw: 'halvparten', qty: 0.5, unit: 'l');
      expect(linkedIngredientLine(half, 'Melk'), '0.5 l Melk');
    });

    test('nothing parsed: the product name alone', () {
      const ing = Ingredient(raw: 'a splash of the white stuff');
      expect(linkedIngredientLine(ing, 'Mellommelk 2,0% fett'),
          'Mellommelk 2,0% fett');
    });
  });

  group('detail screen rendering', () {
    late Directory tmp;
    late LocalFolderStore store;
    late LocalPantryStore pantry;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('myrecibook_detail_link');
      store = LocalFolderStore(Directory('${tmp.path}/recipes'));
      pantry = LocalPantryStore(Directory('${tmp.path}/pantry'));
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Widget app({UnitsModel? units}) => buildApp(
          store: store,
          extractor: NoCallExtractor(),
          picker: () async => [],
          pantry: pantry,
          unitsModel: units,
        );

    Future<void> seed() async {
      await pantry.save(const Product(
        schemaVersion: 1,
        barcode: '7038010000001',
        name: 'Mellommelk 2,0% fett',
        source: 'off',
      ));
      await pantry.save(const Product(
        schemaVersion: 1,
        barcode: '7038010000002',
        name: 'Hvetemel Extra',
        source: 'off',
      ));
      await store.save(
        const Recipe(
          schemaVersion: 1,
          id: 'link-1',
          title: 'Porridge',
          source: RecipeSource(
              type: 'screenshot', importedAt: '2026-08-20T00:00:00.000Z'),
          ingredients: [
            Ingredient(
                raw: '2 dl milk',
                qty: 2,
                unit: 'dl',
                item: 'milk',
                productRef: '7038010000001'),
            Ingredient(
                raw: '1 cup flour', item: 'flour', productRef: '7038010000002'),
            Ingredient(raw: '2 eggs', qty: 2, item: 'eggs'),
          ],
          steps: [RecipeStep(raw: 'Simmer.', confidence: 0.9)],
        ),
        const [],
      );
    }

    Future<void> openDetail(WidgetTester tester) async {
      await tester.pumpWidget(app());
      await settle(tester);
      await tester.tap(find.text('Porridge'));
      await settle(tester);
    }

    testWidgets('linked row: product name inline, one line, no sub-line',
        (tester) async {
      await tester.runAsync(seed);
      await openDetail(tester);

      // The product's name IS the ingredient name, on the qty+unit line.
      expect(find.textContaining('2 dl Mellommelk 2,0% fett', findRichText: true),
          findsOneWidget);
      // The typed name is substituted away, not shown alongside.
      expect(find.textContaining('milk', findRichText: true), findsNothing);
      // No sub-line: the old chip rendered the name as its own plain Text.
      expect(find.text('Mellommelk 2,0% fett'), findsNothing);
      expect(find.text('Hvetemel Extra'), findsNothing);
    });

    testWidgets('unlinked row renders exactly as today', (tester) async {
      await tester.runAsync(seed);
      await openDetail(tester);

      expect(find.text('2 eggs', findRichText: true), findsOneWidget);
    });

    testWidgets('units toggle still converts the substituted line',
        (tester) async {
      await tester.runAsync(seed);
      final units = UnitsModel();
      await tester.pumpWidget(app(units: units));
      await settle(tester);
      await tester.tap(find.text('Porridge'));
      await settle(tester);

      // As written: the raw's own "1 cup" survives around the swapped name.
      expect(find.textContaining('1 cup Hvetemel Extra', findRichText: true),
          findsOneWidget);

      await units.setSystem(UnitSystem.metric);
      await settle(tester);
      expect(find.textContaining('240 ml Hvetemel Extra', findRichText: true),
          findsOneWidget);
      expect(find.textContaining('1 cup', findRichText: true), findsNothing);
    });

    testWidgets('rendering never rewrites the recipe file', (tester) async {
      await tester.runAsync(seed);
      final file = File('${store.root.path}/link-1.json');
      final before = file.readAsStringSync();
      await openDetail(tester);

      expect(file.readAsStringSync(), before);
      expect(before, contains('"raw": "2 dl milk"'));
    });
  });
}
