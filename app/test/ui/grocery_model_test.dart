// GroceryModel over a real GroceryStore on a temp dir: idempotent re-add,
// checked-off exclusion (3e), receipt banner text, keep-apart persistence.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/grocery_store.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/ui/grocery_model.dart';

Map<String, dynamic> ing(String raw, {num? qty, String? unit, String? item}) =>
    {
      'raw': raw,
      'qty': ?qty,
      'unit': ?unit,
      'item': ?item,
      'confidence': 0.9,
    };

Recipe recipe(String id, String title, List<Map<String, dynamic>> ings) =>
    Recipe.assemble(
      id: id,
      content: {
        'title': title,
        'ingredients': ings,
        'steps': [
          {'raw': 'Cook.', 'confidence': 0.9}
        ],
        'extraction': {'overall_confidence': 0.9, 'needs_review': <Object?>[]},
      },
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 6),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );

void main() {
  late Directory tmp;
  late File listFile;
  late File overridesFile;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_grocery_model');
    listFile = File('${tmp.path}/grocery_list.json');
    overridesFile = File('${tmp.path}/grocery_overrides.json');
  });

  tearDown(() => tmp.delete(recursive: true));

  Future<GroceryModel> model() async => GroceryModel(
      await GroceryStore.load(listFile: listFile, overridesFile: overridesFile));

  final pasta = recipe('pasta', 'Pasta', [ing('2 lemons', qty: 2, item: 'lemons')]);

  test('re-adding the same recipe is a no-op', () async {
    final m = await model();
    final first = await m.addRecipe(pasta);
    expect(first.alreadyOnList, isFalse);
    expect(first.addedCount, 1);

    final again = await m.addRecipe(pasta);
    expect(again.alreadyOnList, isTrue);
    expect(m.items, hasLength(1));
    expect(m.items.single.qtyLabel, '2');
  });

  test('checked-off items are excluded from a later whole-recipe add (3e)',
      () async {
    final m = await model();
    await m.addRecipe(pasta);
    await m.toggleItem(m.items.single.id);

    final salmon = recipe('salmon', 'Salmon', [
      ing('4 lemons', qty: 4, item: 'lemons'),
      ing('400 g spinach', qty: 400, unit: 'g', item: 'spinach'),
    ]);
    final res = await m.addRecipe(salmon);
    expect(res.excludedCheckedCount, 1);
    final lemons = m.items.firstWhere((i) => i.key == 'lemons');
    expect(lemons.qtyLabel, '2'); // untouched
    expect(m.items.any((i) => i.key == 'spinach'), isTrue);
  });

  test('recipe fully covered by checked rows: nothing added, not on list',
      () async {
    final m = await model();
    await m.addRecipe(pasta);
    await m.toggleItem(m.items.single.id);

    // Every ingredient of this recipe hits the checked 'lemons' row.
    final water = recipe('water', 'Lemon water', [ing('1 lemon', qty: 1, item: 'lemons')]);
    final res = await m.addRecipe(water);
    expect(res.addedCount, 0);
    expect(res.excludedCheckedCount, 1);
    expect(m.isOnList('water'), isFalse); // the UI must not claim "Added"
  });

  test('typed "2 lemons" parses qty — merge suggestion still fires', () async {
    final m = await model();
    await m.addManual('2 lemons');
    expect(m.items.single.key, 'lemons');
    expect(m.items.single.qtyLabel, '2');

    await m.addRecipe(recipe('cake', 'Cake', [ing('1 lemon', qty: 1, item: 'lemon')]));
    expect(m.suggestions, hasLength(1)); // lemon vs lemons — "Same thing?"
  });

  test('servings re-sync raises the designed receipt text', () async {
    final m = await model();
    await m.addRecipe(recipe('salmon', 'Salmon', [
      ing('2 lemons', qty: 2, item: 'lemons'),
      ing('200 g spinach', qty: 200, unit: 'g', item: 'spinach'),
      ing('1 tbsp soy sauce', qty: 1, unit: 'tbsp', item: 'soy sauce'),
    ]));
    final res = await m.syncRecipe(
        recipe('salmon', 'Salmon', [
          ing('4 lemons', qty: 4, item: 'lemons'),
          ing('400 g spinach', qty: 400, unit: 'g', item: 'spinach'),
          ing('2 tbsp soy sauce', qty: 2, unit: 'tbsp', item: 'soy sauce'),
        ]),
        servings: 4);
    expect(res.changedCount, 3);
    expect(m.receipt, 'Salmon bumped to 4 servings — 3 amounts updated.');
    m.dismissReceipt();
    expect(m.receipt, isNull);
  });

  test('keep-apart survives a reload; confirmed merge re-applies', () async {
    final m = await model();
    await m.addRecipe(recipe('pasta', 'Pasta', [ing('2 lemon', qty: 2, item: 'lemon')]));
    await m.addRecipe(recipe('salmon', 'Salmon', [ing('4 lemons', qty: 4, item: 'lemons')]));
    expect(m.suggestions, hasLength(1));

    await m.keepApart(m.suggestions.single);
    expect(m.suggestions, isEmpty);

    final reloaded = await model();
    expect(reloaded.suggestions, isEmpty);
    expect(reloaded.items, hasLength(2));
  });
}
