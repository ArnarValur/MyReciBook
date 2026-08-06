// Grocery engine: merge rules, idempotent membership, category memory.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/grocery.dart';
import 'package:myrecibook/domain/recipe.dart';

Recipe recipe(String id, List<Ingredient> ings) => Recipe(
      schemaVersion: 1,
      id: id,
      title: id,
      source: const RecipeSource(type: 'screenshot'),
      ingredients: ings,
      steps: const [RecipeStep(raw: 'cook')],
    );

Ingredient ing(String raw, {num? qty, String? unit, String? item}) =>
    Ingredient(raw: raw, qty: qty, unit: unit, item: item);

void main() {
  group('normalizeName', () {
    test('lowercase, trim, collapse, trailing punctuation', () {
      expect(normalizeName('  Fresh   Lemons, '), 'fresh lemons');
      expect(normalizeName('Spaghetti.'), 'spaghetti');
    });

    test('unicode survives — ½ ⅓ é never mangled', () {
      expect(normalizeName('Crème fraîche'), 'crème fraîche');
      expect(normalizeName('½ lemon'), '½ lemon');
    });
  });

  group('addRecipeToList merge', () {
    test('same name + same unit sums (2 + 4 lemons → 6)', () {
      final a = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('2 lemons', qty: 2, item: 'lemons')]));
      final b = addRecipeToList(
          items: a.items,
          recipe: recipe('salmon', [ing('4 lemons', qty: 4, item: 'lemons')]));
      expect(b.items, hasLength(1));
      expect(b.items.single.qtyLabel, '6');
      expect(b.items.single.sourceCount, 2); // "2 recipes" caption
      expect(plannedRecipeCount(b.items), 2);
    });

    test('different or missing units stay side by side, never lost', () {
      final a = addRecipeToList(
          items: const [],
          recipe: recipe('r1',
              [ing('400 g spaghetti', qty: 400, unit: 'g', item: 'spaghetti')]));
      final b = addRecipeToList(
          items: a.items,
          recipe: recipe('r2',
              [ing('1 pack spaghetti', qty: 1, unit: 'pack', item: 'spaghetti')]));
      expect(b.items.single.qtyLabel, '400 g + 1 pack');
    });

    test('qty-less lines keep the raw name, empty quantity', () {
      final r = addRecipeToList(
          items: const [], recipe: recipe('r1', [ing('a splash of vinegar')]));
      expect(r.items.single.name, 'a splash of vinegar');
      expect(r.items.single.qtyLabel, '');
    });

    test('unicode fraction sums render back as fractions', () {
      final r = addRecipeToList(
          items: const [],
          recipe: recipe('r1', [
            ing('½ cup cream', qty: 0.5, unit: 'cup', item: 'cream'),
            ing('¼ cup cream', qty: 0.25, unit: 'cup', item: 'cream'),
          ]));
      expect(r.items.single.qtyLabel, '¾ cup');
      expect(formatQty(1.5), '1½');
      expect(formatQty(1 / 3), '⅓');
      expect(formatQty(2), '2');
    });

    test('same recipe re-add is a no-op (membership guard)', () {
      final a = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('2 lemons', qty: 2, item: 'lemons')]));
      final b = addRecipeToList(
          items: a.items,
          recipe: recipe('pasta', [ing('2 lemons', qty: 2, item: 'lemons')]));
      expect(b.alreadyOnList, isTrue);
      expect(b.items.single.qtyLabel, '2');
      expect(recipeOnList(b.items, 'pasta'), isTrue);
    });

    test('checked item excludes the line from a new add (3e)', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('r1', [ing('spinach', item: 'spinach', qty: 400, unit: 'g')])).items;
      items = toggleChecked(items, items.single.id);
      final r = addRecipeToList(
          items: items,
          recipe: recipe('r2', [
            ing('spinach', item: 'spinach', qty: 200, unit: 'g'),
            ing('2 eggs', qty: 2, item: 'eggs'),
          ]));
      expect(r.excludedCheckedCount, 1);
      expect(r.items.firstWhere((i) => i.key == 'spinach').qtyLabel, '400 g');
      expect(r.items.any((i) => i.key == 'eggs'), isTrue);
    });

    test('staples land dimmed and quantity-less, no duplicates', () {
      final a = addRecipeToList(
          items: const [],
          recipe: recipe('r1',
              [ing('olive oil', item: 'olive oil', qty: 2, unit: 'tbsp')]));
      expect(a.items.single.staple, isTrue);
      expect(a.items.single.qtyLabel, '');
      final b = addRecipeToList(
          items: a.items,
          recipe: recipe('r2', [ing('olive oil', item: 'olive oil')]));
      expect(b.items, hasLength(1));
      final activated = activateStaple(b.items, b.items.single.id);
      expect(activated.single.staple, isFalse);
    });

    test('servings scale multiplies quantities', () {
      final r = addRecipeToList(
          items: const [],
          recipe: recipe('r1', [ing('2 lemons', qty: 2, item: 'lemons')]),
          scale: 2);
      expect(r.items.single.qtyLabel, '4');
    });
  });

  group('removeRecipeFromList', () {
    test('subtracts one contribution, drops sourceless items', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [
            ing('2 lemons', qty: 2, item: 'lemons'),
            ing('spaghetti', item: 'spaghetti', qty: 400, unit: 'g'),
          ])).items;
      items = addRecipeToList(
          items: items,
          recipe: recipe('salmon', [ing('4 lemons', qty: 4, item: 'lemons')])).items;
      final after = removeRecipeFromList(items, 'pasta');
      expect(after.any((i) => i.key == 'spaghetti'), isFalse);
      expect(after.singleWhere((i) => i.key == 'lemons').qtyLabel, '4');
    });

    test('manual items untouched by recipe ops', () {
      var items = addManualItem(items: const [], name: 'Lemons', qty: 1);
      items = addRecipeToList(
          items: items,
          recipe: recipe('pasta', [ing('2 lemons', qty: 2, item: 'lemons')])).items;
      expect(items.single.qtyLabel, '3');
      final after = removeRecipeFromList(items, 'pasta');
      expect(after.single.manual, isTrue);
      expect(after.single.qtyLabel, '1');
    });
  });

  group('updateRecipeOnList (receipt banner)', () {
    test('replaces contribution and counts changed amounts', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('salmon', [
            ing('4 lemons', qty: 4, item: 'lemons'),
            ing('2 fillets', qty: 2, item: 'salmon fillets'),
            ing('rice', item: 'rice', qty: 200, unit: 'g'),
          ])).items;
      final r = updateRecipeOnList(
          items: items,
          recipe: recipe('salmon', [
            ing('4 lemons', qty: 4, item: 'lemons'), // unchanged
            ing('2 fillets', qty: 2, item: 'salmon fillets'),
            ing('rice', item: 'rice', qty: 200, unit: 'g'),
          ]),
          scale: 2);
      // 4→8 lemons, 2→4 fillets, 200→400 g rice: 3 amounts updated
      expect(r.changedCount, 3);
      expect(r.items.firstWhere((i) => i.key == 'lemons').qtyLabel, '8');
    });

    test('recipe not on list → no-op', () {
      final r = updateRecipeOnList(
          items: const [], recipe: recipe('x', [ing('salt', item: 'salt')]));
      expect(r.items, isEmpty);
      expect(r.changedCount, 0);
    });
  });

  group('merge suggestions (suggest-and-confirm, never silent)', () {
    test('singular/plural pair surfaces, keep-apart suppresses', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('1 lemon', qty: 1, item: 'lemon')])).items;
      items = addRecipeToList(
          items: items,
          recipe: recipe('salmon', [ing('4 lemons', qty: 4, item: 'lemons')])).items;
      final s = mergeSuggestions(items);
      expect(s, hasLength(1));
      expect(s.single.keep.key, 'lemons'); // plural survives, per mock
      expect(s.single.mergedQtyLabel, '5');
      expect(
          mergeSuggestions(items,
              keepApart: {mergePairKey('lemon', 'lemons')}),
          isEmpty);
    });

    test('confirmed merge folds items; alias re-applies on next add', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('1 lemon', qty: 1, item: 'lemon')])).items;
      items = addRecipeToList(
          items: items,
          recipe: recipe('salmon', [ing('4 lemons', qty: 4, item: 'lemons')])).items;
      final s = mergeSuggestions(items).single;
      items = mergeItems(items, keepId: s.keep.id, absorbId: s.absorb.id);
      expect(items, hasLength(1));
      expect(items.single.qtyLabel, '5');
      expect(items.single.sourceCount, 2);

      final aliases = {s.absorb.key: s.keep.key};
      final again = addRecipeToList(
          items: items,
          recipe: recipe('cake', [ing('1 lemon', qty: 1, item: 'lemon')]),
          mergeAliases: aliases);
      expect(again.items, hasLength(1)); // no new "lemon" row
      expect(again.items.single.qtyLabel, '6');
    });

    test('alias re-apply onto a cleared list keeps id == key — no dup rows',
        () {
      // Week 2: list cleared, alias lemon→lemons survives by design.
      final aliases = {'lemon': 'lemons'};
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('1 lemon', qty: 1, item: 'lemon')]),
          mergeAliases: aliases).items;
      // The created row IS the canonical item: id, key and name all agree.
      expect(items.single.id, 'lemons');
      expect(items.single.key, 'lemons');
      expect(items.single.name, 'lemons');

      // The canonical recipe folds in — no second row with the same id.
      items = addRecipeToList(
          items: items,
          recipe: recipe('salmon', [ing('4 lemons', qty: 4, item: 'lemons')]),
          mergeAliases: aliases).items;
      expect(items, hasLength(1));
      expect(items.single.qtyLabel, '5');
      expect(items.single.sourceCount, 2);

      // The confirmed pair never resurfaces, and one tap checks one row.
      expect(mergeSuggestions(items), isEmpty);
      final toggled = toggleChecked(items, 'lemons');
      expect(toggled.where((i) => i.checked), hasLength(1));
    });

    test('manual add under an alias keeps id == key too', () {
      final items = addManualItem(
          items: const [], name: 'lemon', mergeAliases: {'lemon': 'lemons'});
      expect(items.single.id, 'lemons');
      expect(items.single.key, 'lemons');
      expect(items.single.name, 'lemons');
    });
  });

  group('manual add', () {
    test('re-adding a checked-off item unchecks it (I need it again)', () {
      var items = addRecipeToList(
          items: const [],
          recipe: recipe('pasta', [ing('2 lemons', qty: 2, item: 'lemons')])).items;
      items = toggleChecked(items, 'lemons');
      items = addManualItem(items: items, name: 'lemons', qty: 1);
      expect(items.single.checked, isFalse);
      expect(items.single.manual, isTrue);
      expect(items.single.qtyLabel, '3');
    });

    test('parseManualEntry peels qty and unit off the merge key', () {
      expect(parseManualEntry('2 lemons'),
          (qty: 2, unit: null, name: 'lemons'));
      expect(parseManualEntry('200 g flour'),
          (qty: 200, unit: 'g', name: 'flour'));
      expect(parseManualEntry('½ cup rice'),
          (qty: 0.5, unit: 'cup', name: 'rice'));
      expect(parseManualEntry('1/2 onion'),
          (qty: 0.5, unit: null, name: 'onion'));
      expect(parseManualEntry('lemons'),
          (qty: null, unit: null, name: 'lemons'));
      // A bare number or unit-less tail never eats the name.
      expect(parseManualEntry('2'), (qty: null, unit: null, name: '2'));
      expect(parseManualEntry('2 g'), (qty: 2, unit: null, name: 'g'));
    });

    test('typed "2 lemons" merges with a later recipe add of lemons', () {
      final p = parseManualEntry('2 lemons');
      var items = addManualItem(
          items: const [], name: p.name, qty: p.qty, unit: p.unit);
      expect(items.single.key, 'lemons');
      items = addRecipeToList(
          items: items,
          recipe: recipe('pasta', [ing('4 lemons', qty: 4, item: 'lemons')])).items;
      expect(items, hasLength(1)); // one row, not two lemon rows forever
      expect(items.single.qtyLabel, '6');
    });
  });

  group('categories', () {
    test('default map: produce vs pantry fallback', () {
      expect(defaultCategoryFor('lemons'), GroceryCategories.produce);
      expect(defaultCategoryFor('cherry tomatoes'), GroceryCategories.produce);
      expect(defaultCategoryFor('sesame oil'), GroceryCategories.pantry);
    });

    test('processed forms are Pantry despite a produce word', () {
      expect(defaultCategoryFor('tomato paste'), GroceryCategories.pantry);
      expect(defaultCategoryFor('garlic powder'), GroceryCategories.pantry);
      expect(defaultCategoryFor('chili sauce'), GroceryCategories.pantry);
      expect(defaultCategoryFor('chili flakes'), GroceryCategories.pantry);
      expect(defaultCategoryFor('corn starch'), GroceryCategories.pantry);
      expect(defaultCategoryFor('tomato'), GroceryCategories.produce);
    });

    test('user override always wins', () {
      expect(categoryFor('sesame oil', {'sesame oil': 'Asian Pantry'}),
          'Asian Pantry');
      expect(categoryFor('lemons', {'lemons': 'Pantry'}), 'Pantry');
      final r = addRecipeToList(
          items: const [],
          recipe: recipe('r1',
              [ing('sesame oil', item: 'sesame oil', qty: 2, unit: 'tbsp')]),
          categoryOverrides: {'sesame oil': 'Asian Pantry'});
      expect(r.items.single.category, 'Asian Pantry');
      expect(GroceryCategories.isStock('Asian Pantry'), isFalse); // pin chip
    });

    test('section order: Produce, user aisles, Pantry', () {
      final cats = ['Pantry', 'Asian Pantry', 'Produce']
        ..sort(GroceryCategories.compare);
      expect(cats, ['Produce', 'Asian Pantry', 'Pantry']);
    });
  });

  test('clearChecked removes bought rows only', () {
    var items = addRecipeToList(
        items: const [],
        recipe: recipe('r1', [
          ing('2 lemons', qty: 2, item: 'lemons'),
          ing('spinach', item: 'spinach', qty: 400, unit: 'g'),
        ])).items;
    items = toggleChecked(items, 'spinach');
    final after = clearChecked(items);
    expect(after.single.key, 'lemons');
  });

  test('setItemCategory produces the moved-by-you result state', () {
    var items = addManualItem(items: const [], name: 'Sesame oil');
    items = setItemCategory(items, items.single.id, 'Asian Pantry');
    expect(items.single.category, 'Asian Pantry');
  });
}
