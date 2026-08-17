// product_ref on Ingredient — the pantry link. Additive field: files that
// never linked must round-trip byte-identical (favorite/cover's rule), and
// copyWith follows cover's tri-state (set / keep / clear).

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/recipe.dart';

void main() {
  test('unlinked ingredient round-trips without a product_ref key', () {
    final json = {
      'raw': '250ml Milk',
      'qty': 250,
      'unit': 'ml',
      'item': 'Milk',
      'note': null,
      'group': null,
      'confidence': 0.95,
    };
    final out = Ingredient.fromJson(json).toJson();
    expect(out.containsKey('product_ref'), isFalse);
    expect(jsonEncode(out), jsonEncode(json));
  });

  test('linked ingredient keeps the ref through a round-trip', () {
    final ing = Ingredient.fromJson({
      'raw': '250ml Milk',
      'product_ref': '7038010071751',
    });
    expect(ing.productRef, '7038010071751');
    expect(Ingredient.fromJson(ing.toJson()).productRef, '7038010071751');
  });

  test('copyWith tri-state: set, keep, clear', () {
    const ing = Ingredient(raw: '250ml Milk');
    final set = ing.copyWith(productRef: '7038010071751');
    expect(set.productRef, '7038010071751');

    final kept = set.copyWith(raw: '300ml Milk');
    expect(kept.productRef, '7038010071751');
    expect(kept.raw, '300ml Milk');

    final cleared = set.copyWith(clearProductRef: true);
    expect(cleared.productRef, isNull);
  });

  test('parsed fields survive a raw edit (existing behavior, still true)', () {
    const ing = Ingredient(
        raw: '250ml Milk', qty: 250, unit: 'ml', item: 'Milk');
    final edited = ing.copyWith(raw: '300ml Milk');
    expect(edited.qty, 250);
    expect(edited.unit, 'ml');
    expect(edited.item, 'Milk');
  });
}
