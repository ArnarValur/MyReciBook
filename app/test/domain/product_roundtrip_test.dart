// Product JSON round-trips — the recipe_roundtrip stance for the pantry:
// every known field survives, missing fields (crowdsourced OFF data) come
// out null instead of throwing, second round-trip is byte-identical.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/product.dart';

void main() {
  _openNutrimentsTests();

  final full = <String, dynamic>{
    'schema_version': 1,
    'barcode': '7038010009457',
    'name': 'Lettmelk',
    'brand': 'Tine',
    'quantity': '1 L',
    'source': 'off',
    'added_at': '2026-08-17T10:00:00Z',
    'nutriments': {
      'kcal': 37.0,
      'fat': 0.5,
      'saturated_fat': 0.3,
      'carbs': 4.5,
      'sugars': 4.5,
      'protein': 3.5,
      'salt': 0.1,
    },
  };

  group('full file', () {
    test('fromJson preserves every known field', () {
      final p = Product.fromJson(full);
      expect(p.schemaVersion, 1);
      expect(p.barcode, '7038010009457');
      expect(p.name, 'Lettmelk');
      expect(p.brand, 'Tine');
      expect(p.quantity, '1 L');
      expect(p.source, 'off');
      expect(p.addedAt, '2026-08-17T10:00:00Z');
      expect(p.nutriments!.kcal, 37.0);
      expect(p.nutriments!.fat, 0.5);
      expect(p.nutriments!.saturatedFat, 0.3);
      expect(p.nutriments!.carbs, 4.5);
      expect(p.nutriments!.sugars, 4.5);
      expect(p.nutriments!.protein, 3.5);
      expect(p.nutriments!.salt, 0.1);
    });

    test('second round-trip is byte-identical', () {
      final first = Product.fromJson(full).toJson();
      final second =
          Product.fromJson(jsonDecode(jsonEncode(first)) as Map<String, dynamic>)
              .toJson();
      expect(second, first);
      expect(jsonEncode(second), jsonEncode(first));
    });
  });

  group('missing fields (crowdsourced OFF data)', () {
    test('sparse nutriments: absent keys come out null, present survive', () {
      final p = Product.fromJson(<String, dynamic>{
        'schema_version': 1,
        'barcode': '123',
        'name': 'Mystery snack',
        'source': 'off',
        'nutriments': {'kcal': 512, 'salt': 1.2},
      });
      expect(p.nutriments!.kcal, 512.0);
      expect(p.nutriments!.salt, 1.2);
      expect(p.nutriments!.fat, isNull);
      expect(p.nutriments!.saturatedFat, isNull);
      expect(p.nutriments!.carbs, isNull);
      expect(p.nutriments!.sugars, isNull);
      expect(p.nutriments!.protein, isNull);
    });

    test('no nutriments / no brand / no quantity / no added_at → nulls', () {
      final p = Product.fromJson(<String, dynamic>{
        'schema_version': 1,
        'barcode': '',
        'name': 'Salt',
        'source': 'manual',
      });
      expect(p.nutriments, isNull);
      expect(p.brand, isNull);
      expect(p.quantity, isNull);
      expect(p.addedAt, isNull);
      // Sparse in → still a complete file out (all keys present, null values).
      final back = Product.fromJson(
          jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(jsonEncode(back.toJson()), jsonEncode(p.toJson()));
    });

    test('missing barcode tolerated as empty (pre-barcode manual files)', () {
      final p = Product.fromJson(<String, dynamic>{
        'schema_version': 1,
        'name': 'Hveiti',
        'source': 'manual',
      });
      expect(p.barcode, '');
    });
  });

  group('id (filename stem)', () {
    test('barcode wins when present', () {
      expect(Product.fromJson(full).id, '7038010009457');
    });

    test('manual product falls back to a name slug', () {
      const p = Product(
        schemaVersion: 1,
        barcode: '',
        name: "Nan's Rye Bread",
        source: 'manual',
      );
      expect(p.id, 'nan-s-rye-bread');
    });

    test('slug is never empty and never escapes the folder', () {
      expect(slugifyProductName('???'), 'product');
      expect(slugifyProductName('../../etc/passwd'), 'etc-passwd');
      expect(slugifyProductName('  Rúgbrauð  '), 'r-gbrau');
    });
  });

  group('productProblems', () {
    test('valid file → no problems', () {
      expect(productProblems(full), isEmpty);
    });

    test('empty name and missing fields are flagged', () {
      expect(productProblems(<String, dynamic>{'schema_version': 1, 'source': 'off'}),
          containsAll(<String>['missing:name', 'empty name']));
      expect(
          productProblems(<String, dynamic>{
            'schema_version': 1,
            'name': '',
            'source': 'manual',
          }),
          ['empty name']);
    });

    test('unknown schema_version is flagged', () {
      expect(
          productProblems(<String, dynamic>{
            'schema_version': 2,
            'name': 'Milk',
            'source': 'off',
          }),
          ['unknown schema_version 2']);
    });

    test('source value is not pinned (schema-additive, the recipe stance)', () {
      expect(
          productProblems(<String, dynamic>{
            'schema_version': 1,
            'name': 'Milk',
            'source': 'some-future-source',
          }),
          isEmpty);
    });
  });

  group('copyWith', () {
    final base = Product.fromJson(full);

    test('changes only what was passed', () {
      final edited = base.copyWith(name: 'Lettmelk 0.5%', brand: 'Q');
      expect(edited.name, 'Lettmelk 0.5%');
      expect(edited.brand, 'Q');
      final expected = base.toJson()
        ..['name'] = 'Lettmelk 0.5%'
        ..['brand'] = 'Q';
      expect(edited.toJson(), expected);
    });

    test('no args = identical output', () {
      expect(base.copyWith().toJson(), base.toJson());
    });
  });
}

// ---------------------------------------------------------------------------
// Vitamins and minerals in the saved file. Products written before
// 2026-08-18 hold exactly seven keys, some of them null; new ones hold
// whatever Open Food Facts had. Both must load, and neither may lose data.
// ---------------------------------------------------------------------------

void _openNutrimentsTests() {
  group('nutriments as an open map', () {
    test('a file written by the old build still loads, nulls dropped', () {
      final json = {
        'schema_version': 1,
        'barcode': '7038010071751',
        'name': 'Mellommelk 2,0% fett',
        'source': 'off',
        'nutriments': {
          'kcal': 50,
          'fat': 2,
          'saturated_fat': 1.3,
          'carbs': 4.6,
          'sugars': 4.6,
          'protein': 3.5,
          'salt': null,
        },
      };
      final n = Product.fromJson(json).nutriments!;

      expect(n.kcal, 50.0);
      expect(n.saturatedFat, 1.3);
      expect(n.salt, isNull);
      expect(n.extraKeys, isEmpty);
    });

    test('vitamins and minerals survive save and load', () {
      final product = Product(
        schemaVersion: 1,
        barcode: '7038010071751',
        name: 'Mellommelk 2,0% fett',
        source: 'off',
        nutriments: const Nutriments.fromMap({
          'kcal': 50,
          'protein': 3.5,
          'calcium': 0.118,
          'vitamin_d': 8e-07,
          'iodine': 1.67e-06,
        }),
      );

      final reloaded = Product.fromJson(
          jsonDecode(jsonEncode(product.toJson())) as Map<String, dynamic>);
      final n = reloaded.nutriments!;

      expect(n.kcal, 50.0);
      expect(n['calcium'], 0.118);
      expect(n['vitamin_d'], 8e-07);
      expect(n['iodine'], 1.67e-06);
      expect(n.extraKeys, ['calcium', 'iodine', 'vitamin_d']);
    });

    test('macros lead the written file, in label order', () {
      const n = Nutriments.fromMap({
        'calcium': 0.118,
        'salt': 0.1,
        'kcal': 50,
        'fat': 2,
      });
      expect(n.toJson().keys.toList(), ['kcal', 'fat', 'salt', 'calcium']);
    });

    test('a product with only a mineral gains no empty macro keys', () {
      const n = Nutriments.fromMap({'calcium': 0.118});
      expect(n.toJson(), {'calcium': 0.118});
    });
  });
}
