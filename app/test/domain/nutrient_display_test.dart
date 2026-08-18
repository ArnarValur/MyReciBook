// Units on screen. Storage keeps Open Food Facts' grams; only the display
// steps down to mg and µg, so 0.118 g of calcium reads as 118 mg instead of
// a row of leading zeros. Real values from Tine Mellommelk throughout.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/nutrient_display.dart';

void main() {
  group('formatNutrient', () {
    test('energy keeps its own units, never grams', () {
      expect(formatNutrient('kcal', 50), ('50', 'kcal'));
      expect(formatNutrient('energy_kj', 212), ('212', 'kJ'));
    });

    test('a gram or more stays in grams', () {
      expect(formatNutrient('protein', 3.5), ('3.5', 'g'));
      expect(formatNutrient('fat', 2), ('2', 'g'));
    });

    test('minerals step down to milligrams', () {
      expect(formatNutrient('calcium', 0.118), ('118', 'mg'));
      expect(formatNutrient('phosphorus', 0.0994), ('99.4', 'mg'));
      expect(formatNutrient('salt', 0.1), ('100', 'mg'));
    });

    test('trace amounts step down to micrograms', () {
      expect(formatNutrient('vitamin_d', 8e-07), ('0.8', 'µg'));
      expect(formatNutrient('iodine', 1.67e-06), ('1.67', 'µg'));
      expect(formatNutrient('biotin', 5.6e-06), ('5.6', 'µg'));
    });

    test('zero stays a plain zero in grams', () {
      expect(formatNutrient('iron', 0), ('0', 'g'));
    });

    test('long decimals are cut to two places, trailing zeros removed', () {
      expect(formatNutrient('sugars', 4.6000000000000005), ('4.6', 'g'));
      expect(formatNutrient('calcium', 0.1183456), ('118.35', 'mg'));
    });
  });

  group('nutrientLabel', () {
    test('known nutrients read as English', () {
      expect(nutrientLabel('kcal'), 'Energy');
      expect(nutrientLabel('saturated_fat'), '— of which saturated');
      expect(nutrientLabel('vitamin_b12'), 'Vitamin B12');
      expect(nutrientLabel('calcium'), 'Calcium');
    });

    test('an unknown key is still shown, never hidden', () {
      expect(nutrientLabel('some_new_off_field'), 'Some new off field');
      expect(nutrientLabel(''), '');
    });
  });
}
