// The calculator's honesty contract: grams only when they can be known,
// coverage always counted, per-serving only when the recipe says servings.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/ingredient_parse.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/domain/recipe_nutrition.dart';

Product milk() => Product(
      schemaVersion: 1,
      barcode: 'milk1',
      name: 'Mellommelk',
      source: 'off',
      nutriments: Nutriments(kcal: 50, protein: 3.5),
    );

Product banana() => Product(
      schemaVersion: 1,
      barcode: '',
      name: 'Banana',
      source: 'manual',
      nutriments: Nutriments(kcal: 89),
      servings: const [Serving(label: '1 medium', grams: 118)],
    );

void main() {
  group('parseIngredientLine', () {
    (num?, String?, String) p(String raw) {
      final r = parseIngredientLine(raw);
      return (r.qty, r.unit, r.item);
    }

    test('plain grams', () => expect(p('400 g pasta'), (400, 'g', 'pasta')));
    test('glued unit', () => expect(p('400g pasta'), (400, 'g', 'pasta')));
    test('decimal comma', () => expect(p('1,5 dl cream'), (1.5, 'dl', 'cream')));
    test('slash fraction', () => expect(p('1/2 tsp salt'), (0.5, 'tsp', 'salt')));
    test('mixed number', () {
      final r = parseIngredientLine('1 1/2 cups flour');
      expect(r.qty, closeTo(1.5, 1e-9));
      expect(r.unit, 'cup');
      expect(r.item, 'flour');
    });
    test('unicode fraction, glued', () {
      final r = parseIngredientLine('1½ tbsp oil');
      expect(r.qty, closeTo(1.5, 1e-9));
      expect(r.unit, 'tbsp');
    });
    test('range keeps the low end',
        () => expect(p('2-3 tbsp sugar'), (2, 'tbsp', 'sugar')));
    test('multiplied pack', () {
      final r = parseIngredientLine('2 x 400 g chopped tomatoes');
      expect(r.qty, 800);
      expect(r.unit, 'g');
    });
    test('count with no unit',
        () => expect(p('2 large eggs'), (2, null, 'large eggs')));
    test('"of" is dropped',
        () => expect(p('2 dl of milk'), (2, 'dl', 'milk')));
    test('no number at all',
        () => expect(p('salt to taste'), (null, null, 'salt to taste')));
    test('never throws on junk', () {
      for (final raw in ['', '   ', '1/0 x', '½', '2 x', '×']) {
        expect(() => parseIngredientLine(raw), returnsNormally);
      }
    });
  });

  group('ingredientGrams', () {
    test('mass units convert directly', () {
      expect(ingredientGrams(Ingredient(raw: '400 g pasta'), null), 400);
      expect(ingredientGrams(Ingredient(raw: '1 kg flour'), null), 1000);
      expect(
          ingredientGrams(Ingredient(raw: '1 lb beef'), null), closeTo(453.6, 0.1));
    });

    test('volume needs a density match — milk resolves, mystery does not', () {
      expect(ingredientGrams(Ingredient(raw: '2 dl milk'), milk()),
          closeTo(206, 0.5)); // 200 ml × 1.03
      expect(ingredientGrams(Ingredient(raw: '2 dl secret sauce'), null),
          isNull);
    });

    test('density can come from the product name too', () {
      // The line says "2 dl" of something unnamed; the linked product says milk.
      final ing = Ingredient(raw: 'about stuff', qty: 2, unit: 'dl', item: 'stuff');
      expect(ingredientGrams(ing, milk()), closeTo(206, 0.5));
    });

    test('a count uses the product portion weight', () {
      expect(ingredientGrams(Ingredient(raw: '2 bananas'), banana()), 236);
      expect(ingredientGrams(Ingredient(raw: '2 bananas'), milk()), isNull,
          reason: 'no per-piece weight on the product = no guess');
    });

    test('extractor parse wins over the raw line', () {
      final ing = Ingredient(raw: 'nonsense text', qty: 50, unit: 'g', item: 'x');
      expect(ingredientGrams(ing, null), 50);
    });

    test('pinch and can stay uncovered', () {
      expect(ingredientGrams(Ingredient(raw: '1 pinch salt'), null), isNull);
      expect(ingredientGrams(Ingredient(raw: '1 can beans'), null), isNull);
    });
  });

  group('recipeNutrition', () {
    Recipe recipe(List<Ingredient> ings, {Servings? servings}) => Recipe(
          schemaVersion: 2,
          id: 'r1',
          title: 'Test',
          source: RecipeSource(type: 'manual'),
          servings: servings,
          ingredients: ings,
          steps: const [],
        );

    test('sums covered ingredients and counts honestly', () {
      final r = recipe([
        Ingredient(raw: '2 dl milk', productRef: 'milk1'),
        Ingredient(raw: '1 banana', productRef: 'banana'),
        Ingredient(raw: 'salt to taste'), // no qty
        Ingredient(raw: '100 g mystery'), // no link
      ], servings: Servings(amount: 2));
      final n = recipeNutrition(r, {'milk1': milk(), 'banana': banana()});
      expect(n.covered, 2);
      expect(n.ingredientCount, 4);
      expect(n.isComplete, isFalse);
      // 206 g milk ×0.5 + 118 g banana ×0.89
      expect(n.total.kcal, closeTo(103 + 105.02, 0.5));
      expect(n.perServing!.kcal, closeTo(n.total.kcal! / 2, 1e-9));
    });

    test('no servings on file → no per-serving number', () {
      final r = recipe([Ingredient(raw: '2 dl milk', productRef: 'milk1')]);
      final n = recipeNutrition(r, {'milk1': milk()});
      expect(n.covered, 1);
      expect(n.perServing, isNull);
    });

    test('servings from raw text — "Serves 4"', () {
      final r = recipe([Ingredient(raw: '2 dl milk', productRef: 'milk1')],
          servings: Servings(raw: 'Serves 4'));
      expect(recipeNutrition(r, {'milk1': milk()}).perServing, isNotNull);
    });

    test('nothing linked → isEmpty, zero total, never a crash', () {
      final n = recipeNutrition(recipe([Ingredient(raw: '1 egg')]), {});
      expect(n.isEmpty, isTrue);
      expect(n.total.values, isEmpty);
    });

    test('a dangling productRef is skipped, not fatal', () {
      final r = recipe([Ingredient(raw: '2 dl milk', productRef: 'gone')]);
      expect(recipeNutrition(r, {}).covered, 0);
    });
  });
}
