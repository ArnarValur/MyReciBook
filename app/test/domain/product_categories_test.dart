// categoryForOff — OFF classification → shelf category. The mapping table's
// contract: deep taxonomy beats food groups, fine groups beat broad ones,
// nothing usable → null (never a guess).

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/product_categories.dart';

Product _p(String name, {List<String> tags = const []}) => Product(
      schemaVersion: 1,
      barcode: '',
      name: name,
      source: 'manual',
      tags: tags,
    );

void main() {
  test('fine PNNS group wins: milk lands in Dairy', () {
    expect(
        categoryForOff(foodGroupsTags: [
          'en:milk-and-dairy-products',
          'en:milk-and-yogurt',
        ]),
        'Dairy');
  });

  test('fine beats broad even though OFF lists broad first', () {
    expect(
        categoryForOff(foodGroupsTags: [
          'en:milk-and-dairy-products',
          'en:cheese',
        ]),
        'Cheese');
  });

  test('broad group is the fallback when no fine entry matches', () {
    expect(categoryForOff(foodGroupsTags: ['en:beverages']), 'Drinks');
  });

  test('categories_tags override: chicken is Chicken, not Meat', () {
    expect(
        categoryForOff(
          categoriesTags: ['en:meats', 'en:poultries', 'en:chickens'],
          foodGroupsTags: ['en:fish-meat-eggs', 'en:poultry'],
        ),
        'Chicken');
  });

  test('categories_tags override: berries beat the Fruit group', () {
    expect(
        categoryForOff(
          categoriesTags: ['en:plant-based-foods', 'en:fruits', 'en:berries'],
          foodGroupsTags: ['en:fruits-and-vegetables', 'en:fruits'],
        ),
        'Berries');
  });

  test('wine lands in Wine & beer via the alcoholic-beverages group', () {
    expect(
        categoryForOff(foodGroupsTags: [
          'en:beverages',
          'en:alcoholic-beverages',
        ]),
        'Wine & beer');
  });

  test('tran: cod-liver-oil category override → Oils', () {
    expect(
        categoryForOff(
          categoriesTags: ['en:cod-liver-oils'],
          foodGroupsTags: ['en:fish-meat-eggs'],
        ),
        'Oils');
  });

  test('empty food groups: broad category taxonomy carries it (kjøttboller)',
      () {
    expect(
        categoryForOff(
          categoriesTags: [
            'en:meats-and-their-products',
            'en:meat-preparations',
            'en:meat-balls',
          ],
          foodGroupsTags: [],
        ),
        'Meat');
  });

  test('nothing usable → null, never a guess', () {
    expect(categoryForOff(), isNull);
    expect(categoryForOff(foodGroupsTags: ['en:unknown']), isNull);
    expect(categoryForOff(categoriesTags: ['en:some-exotic-thing']), isNull);
  });

  test('every mapped value is a canonical category', () {
    for (final tags in [
      ['en:milk-and-yogurt'],
      ['en:sweets'],
      ['en:one-dish-meals'],
      ['en:breakfast-cereals'],
      ['en:eggs'],
    ]) {
      expect(productCategories, contains(categoryForOff(foodGroupsTags: tags)));
    }
  });

  group('the grouped shelf', () {
    test('buckets by first tag, canonical order, Other last, a-z inside', () {
      final groups = groupByCategory([
        _p('Zucchini', tags: ['Veggies']),
        _p('Mystery jar'),
        _p('Norvegia', tags: ['Cheese']),
        _p('Aspargus', tags: ['Veggies']),
        _p('Lakris', tags: ['Godteri']), // custom tag
      ]);

      expect([for (final (name, _) in groups) name],
          ['Cheese', 'Veggies', 'Godteri', 'Other']);
      final veggies = groups[1].$2;
      expect([for (final p in veggies) p.name], ['Aspargus', 'Zucchini']);
    });

    test('counts are membership-based and ordered like the shelf', () {
      final counts = categoryCounts([
        _p('Havregryn', tags: ['Breakfast', 'Pasta & grains']),
        _p('Melk', tags: ['Dairy']),
        _p('Mystery jar'),
      ]);

      expect(counts,
          {'Dairy': 1, 'Pasta & grains': 1, 'Breakfast': 1, 'Other': 1});
      expect(counts.keys.toList(),
          ['Dairy', 'Pasta & grains', 'Breakfast', 'Other']);
    });

    test('compareCategories: canonical beats custom, Other beats nothing',
        () {
      expect(compareCategories('Dairy', 'Cheese'), isNegative);
      expect(compareCategories('Dairy', 'Godteri'), isNegative);
      expect(compareCategories('Godteri', 'Aaa'), isPositive);
      expect(compareCategories('Other', 'Zzz'), isPositive);
    });
  });
}
