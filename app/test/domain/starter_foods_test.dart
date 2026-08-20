// Starter foods — the bundled table's contract: every food converts to a
// valid, EU-convention product file with its category tag and natural
// serving; the packages themselves are internally consistent.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/product_categories.dart';
import 'package:myrecibook/domain/starter_foods.dart';

void main() {
  test('three packages, expected sizes', () {
    expect(starterPackages, hasLength(3));
    expect(starterPackages[0].foods, hasLength(65)); // Vegetables
    expect(starterPackages[1].foods, hasLength(49)); // Fruits & Berries
    expect(starterPackages[2].foods, hasLength(35)); // Spices & Herbs
  });

  test('toProduct: EU carbs = USDA carbs minus fiber', () {
    // Red Bell Pepper: USDA 6.0 carbs, 2.1 fiber → EU 3.9.
    final pepper = starterPackages[0]
        .foods
        .firstWhere((f) => f.name == 'Red Bell Pepper')
        .toProduct();
    expect(pepper.nutriments?.carbs, closeTo(3.9, 1e-9));
    expect(pepper.nutriments?.values['fiber'], 2.1);
    expect(pepper.nutriments?.kcal, 31);
  });

  test('toProduct: barcodeless starter file, tagged, serving preselected',
      () {
    final pepper = starterPackages[0]
        .foods
        .firstWhere((f) => f.name == 'Orange Bell Pepper')
        .toProduct(addedAt: '2026-08-20T12:00:00.000Z');
    expect(pepper.barcode, isEmpty);
    expect(pepper.id, 'orange-bell-pepper');
    expect(pepper.source, 'starter');
    expect(pepper.tags, ['Veggies']);
    expect(pepper.synonyms, contains('Oransje paprika'));
    expect(pepper.preferredServing.label, '1 medium');
    expect(pepper.preferredServing.grams, 119);
    expect(pepper.userEdited, isFalse);
    expect(productProblems(pepper.toJson()), isEmpty);
  });

  test('a spice: kcal only, tsp serving, still a valid file', () {
    final cumin = starterPackages[2]
        .foods
        .firstWhere((f) => f.name == 'Ground Cumin')
        .toProduct();
    expect(cumin.nutriments?.kcal, 375);
    expect(cumin.nutriments?.carbs, isNull);
    expect(cumin.preferredServing.grams, 2.1);
    expect(productProblems(cumin.toJson()), isEmpty);
  });

  test('every food: canonical category, unique id, valid file, roundtrips',
      () {
    final seen = <String>{};
    for (final pack in starterPackages) {
      for (final food in pack.foods) {
        final p = food.toProduct();
        expect(productCategories, contains(food.category),
            reason: food.name);
        expect(seen.add(p.id), isTrue,
            reason: '${food.name}: duplicate id ${p.id}');
        expect(productProblems(p.toJson()), isEmpty, reason: food.name);
        final back = Product.fromJson(p.toJson());
        expect(back.synonyms, p.synonyms, reason: food.name);
        expect(back.nutriments?.values, p.nutriments?.values,
            reason: food.name);
      }
    }
  });
}
