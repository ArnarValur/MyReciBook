// GroceryStore: two-file persistence — list state + remembered merges.
// Corrupt files start clean; clearing the list keeps the merge memory.

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
    expect(s.mergeAliases, isEmpty);
    expect(s.keepApartPairs, isEmpty);
  });

  test('round-trip: items and merge memory survive reload', () async {
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
    await s.confirmMerge(canonicalKey: 'lemons', aliasKey: 'lemon');
    await s.recordKeepApart('spring onion', 'onion');

    final r = await load();
    expect(r.items, hasLength(2));
    expect(r.items.first.name, 'Crème fraîche'); // unicode intact on disk
    expect(r.items.first.checked, isTrue);
    expect(r.items.first.qtyLabel, '½ cup');
    expect(r.items.last.name, '½ lemon');
    expect(r.mergeAliases, {'lemon': 'lemons'});
    expect(r.keepApartPairs, {mergePairKey('onion', 'spring onion')});
  });

  test('corrupt files → start clean, never throw', () async {
    await listFile().create(recursive: true);
    await listFile().writeAsString('{broken');
    await overridesFile().writeAsString(jsonEncode({'merge_aliases': 'nope'}));

    final s = await load();
    expect(s.items, isEmpty);
    expect(s.mergeAliases, isEmpty);

    // still writable after recovery
    await s.confirmMerge(canonicalKey: 'lemons', aliasKey: 'lemon');
    expect((await load()).mergeAliases, {'lemon': 'lemons'});
  });

  // Devices that used the old aisle-correction feature still carry a
  // 'categories' key on disk: it is ignored on read and dropped on the next
  // write, and the merge memory beside it is untouched.
  test('a leftover aisle-override key is ignored, merge memory survives',
      () async {
    await overridesFile().create(recursive: true);
    await overridesFile().writeAsString(jsonEncode({
      'version': 1,
      'categories': {'sesame oil': 'Asian Pantry'},
      'merge_aliases': {'lemon': 'lemons'},
      'keep_apart': <String>[],
    }));

    final s = await load();
    expect(s.mergeAliases, {'lemon': 'lemons'});

    await s.confirmMerge(canonicalKey: 'onions', aliasKey: 'onion');
    final data = jsonDecode(await overridesFile().readAsString())
        as Map<String, dynamic>;
    expect(data.containsKey('categories'), isFalse);
    expect(data['merge_aliases'], {'lemon': 'lemons', 'onion': 'onions'});
  });

  test('clearList wipes items but the merge memory survives', () async {
    final s = await load();
    await s.saveItems([
      const GroceryItem(id: 'lemons', name: 'lemons', category: 'Produce'),
    ]);
    await s.confirmMerge(canonicalKey: 'lemons', aliasKey: 'lemon');
    await s.clearList();

    final r = await load();
    expect(r.items, isEmpty);
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

  // product_ref (N8) is additive: old lists know nothing of it and must
  // keep loading — and re-saving — exactly as before.
  test('old list without product_ref loads unchanged and never gains the key',
      () async {
    await listFile().create(recursive: true);
    await listFile().writeAsString(jsonEncode({
      'version': 1,
      'items': [
        {
          'id': 'lemons',
          'name': 'lemons',
          'category': 'Produce',
          'recipe_parts': {
            'pasta': [
              {'qty': 2, 'unit': null}
            ]
          },
        },
      ],
    }));

    final s = await load();
    expect(s.items.single.productRef, isNull);
    expect(s.items.single.qtyLabel, '2'); // everything else as before

    await s.saveItems(s.items);
    final raw = jsonDecode(await listFile().readAsString()) as Map<String, dynamic>;
    final row = (raw['items'] as List).single as Map<String, dynamic>;
    expect(row.containsKey('product_ref'), isFalse);
  });

  test('product_ref survives a save/reload round-trip', () async {
    final s = await load();
    await s.saveItems([
      const GroceryItem(
          id: 'milk',
          name: 'milk',
          category: 'Pantry',
          productRef: '7038010071751'),
    ]);
    expect((await load()).items.single.productRef, '7038010071751');
  });

  test('heal keeps a ref when folding duplicate ids', () async {
    await listFile().create(recursive: true);
    await listFile().writeAsString(jsonEncode({
      'version': 1,
      'items': [
        {'id': 'milk', 'name': 'milk', 'category': 'Pantry'},
        {
          'id': 'milk',
          'name': 'milk',
          'category': 'Pantry',
          'product_ref': '7038010071751',
        },
      ],
    }));

    final s = await load();
    expect(s.items.single.productRef, '7038010071751');
  });
}
