// GroceryStore: two-file persistence — list state + remembered corrections.
// Corrupt files start clean; clearing the list keeps the corrections.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/grocery_store.dart';
import 'package:myrecibook/domain/grocery.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_grocery_test');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  File listFile() => File('${tmp.path}/nested/grocery_list.json');
  File overridesFile() => File('${tmp.path}/nested/grocery_overrides.json');

  Future<GroceryStore> load() =>
      GroceryStore.load(listFile: listFile(), overridesFile: overridesFile());

  test('missing files → empty defaults', () async {
    final s = await load();
    expect(s.items, isEmpty);
    expect(s.categoryOverrides, isEmpty);
    expect(s.mergeAliases, isEmpty);
    expect(s.keepApartPairs, isEmpty);
  });

  test('round-trip: items, overrides, merge memory survive reload', () async {
    final s = await load();
    await s.saveItems([
      const GroceryItem(
        id: 'crème fraîche',
        name: 'Crème fraîche',
        category: 'Pantry',
        checked: true,
        recipeParts: {
          'r1': [QtyPart(qty: 0.5, unit: 'cup')]
        },
      ),
      // id must equal the key (engine invariant) — load heals divergence.
      const GroceryItem(
          id: '½ lemon', name: '½ lemon', category: 'Produce', manual: true),
    ]);
    await s.setCategoryOverride('sesame oil', 'Asian Pantry');
    await s.confirmMerge(canonicalKey: 'lemons', aliasKey: 'lemon');
    await s.recordKeepApart('spring onion', 'onion');

    final r = await load();
    expect(r.items, hasLength(2));
    expect(r.items.first.name, 'Crème fraîche'); // unicode intact on disk
    expect(r.items.first.checked, isTrue);
    expect(r.items.first.qtyLabel, '½ cup');
    expect(r.items.last.name, '½ lemon');
    expect(r.categoryOverrides, {'sesame oil': 'Asian Pantry'});
    expect(r.mergeAliases, {'lemon': 'lemons'});
    expect(r.keepApartPairs, {mergePairKey('onion', 'spring onion')});
  });

  test('corrupt files → start clean, never throw', () async {
    await listFile().create(recursive: true);
    await listFile().writeAsString('{broken');
    await overridesFile().writeAsString(jsonEncode({'categories': 'nope'}));

    final s = await load();
    expect(s.items, isEmpty);
    expect(s.categoryOverrides, isEmpty);

    // still writable after recovery
    await s.setCategoryOverride('rice', 'Asian Pantry');
    expect((await load()).categoryOverrides, {'rice': 'Asian Pantry'});
  });

  test('clearList wipes items but corrections survive', () async {
    final s = await load();
    await s.saveItems([
      const GroceryItem(id: 'lemons', name: 'lemons', category: 'Produce'),
    ]);
    await s.setCategoryOverride('sesame oil', 'Asian Pantry');
    await s.confirmMerge(canonicalKey: 'lemons', aliasKey: 'lemon');
    await s.clearList();

    final r = await load();
    expect(r.items, isEmpty);
    expect(r.categoryOverrides, {'sesame oil': 'Asian Pantry'});
    expect(r.mergeAliases, {'lemon': 'lemons'});
  });

  test('overlapping saves serialize — last write wins, file stays whole',
      () async {
    final s = await load();
    // Un-awaited rapid check-offs: 30 in-flight saves over one tmp path.
    final saves = [
      for (var n = 1; n <= 30; n++)
        s.saveItems([
          for (var j = 0; j < n; j++)
            GroceryItem(id: 'item $j', name: 'item $j', category: 'Pantry'),
        ])
    ];
    await Future.wait(saves);

    final r = await load();
    expect(r.items, hasLength(30)); // the last save, intact — never wiped
  });

  test('load heals pre-fix rows: key != id renamed, duplicate ids folded',
      () async {
    // State written by the old alias bug: two rows with the SAME id, one
    // whose name no longer matches it.
    await listFile().create(recursive: true);
    await listFile().writeAsString(jsonEncode({
      'version': 1,
      'items': [
        {
          'id': 'lemons',
          'name': 'lemon', // key 'lemon' != id 'lemons'
          'category': 'Produce',
          'recipe_parts': {
            'pasta': [
              {'qty': 2, 'unit': null}
            ]
          },
        },
        {
          'id': 'lemons',
          'name': 'lemons',
          'category': 'Produce',
          'recipe_parts': {
            'salmon': [
              {'qty': 4, 'unit': null}
            ]
          },
        },
      ],
    }));

    final s = await load();
    expect(s.items, hasLength(1));
    final item = s.items.single;
    expect(item.id, 'lemons');
    expect(item.key, 'lemons');
    expect(item.name, 'lemons');
    expect(item.qtyLabel, '6'); // both contributions kept
    expect(item.sourceCount, 2);
  });

  test('removeCategoryOverride persists', () async {
    final s = await load();
    await s.setCategoryOverride('rice', 'Asian Pantry');
    await s.removeCategoryOverride('rice');
    expect((await load()).categoryOverrides, isEmpty);
  });
}
