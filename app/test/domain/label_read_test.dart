// labelReadFromJson: the half that refuses to trust the model.
//
// The prompt asks it to omit anything it cannot read, because the pantry's
// rule is that a blank field means "not measured" and never zero. These pin
// the second half of that promise — a hallucinated number must not reach a
// form the person will tap Save on.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/label_read.dart';

void main() {
  test('a clean printed label comes through whole', () {
    final r = labelReadFromJson({
      'name': 'Havregryn Store',
      'brand': 'Axa',
      'per_100g': {'kcal': 370, 'fat': 7.0, 'protein': 13.0, 'salt': 0.01},
      'serving': {'label': '1 dl', 'grams': 35},
      'basis': 'printed',
      'confidence': 0.9,
    });
    expect(r.name, 'Havregryn Store');
    expect(r.brand, 'Axa');
    expect(r.values['kcal'], 370);
    expect(r.values['salt'], 0.01);
    expect(r.serving?.label, '1 dl');
    expect(r.serving?.grams, 35);
    expect(r.basis, LabelBasis.printed);
    expect(r.hasAnything, isTrue);
  });

  test('an absent key stays absent — never becomes a zero', () {
    final r = labelReadFromJson({
      'per_100g': {'kcal': 120},
    });
    expect(r.values.containsKey('sugars'), isFalse);
    expect(r.values['kcal'], 120);
  });

  test('impossible numbers are dropped, not clamped', () {
    // 800 g of fat in 100 g is a misread decimal point. Clamping it to 100
    // would invent a number; dropping it leaves the field blank for a human.
    final r = labelReadFromJson({
      'per_100g': {'fat': 800, 'kcal': 5000, 'protein': 12, 'salt': -3},
    });
    expect(r.values.containsKey('fat'), isFalse);
    expect(r.values.containsKey('kcal'), isFalse);
    expect(r.values.containsKey('salt'), isFalse);
    expect(r.values['protein'], 12);
  });

  test('a table whose macros exceed 100 g keeps only the energy', () {
    final r = labelReadFromJson({
      'name': 'Something',
      'per_100g': {'fat': 60, 'carbs': 60, 'protein': 30, 'kcal': 400},
    });
    expect(r.values.keys, ['kcal']);
    expect(r.name, 'Something', reason: 'the name is usually still right');
  });

  test('vitamins ride along without this file knowing about them', () {
    final r = labelReadFromJson({
      'per_100g': {'kcal': 90, 'calcium': 120, 'vitamin_d': 0.75, 'Bad Key!': 3},
    });
    expect(r.values['calcium'], 120);
    expect(r.values['vitamin_d'], 0.75);
    expect(r.values.containsKey('Bad Key!'), isFalse);
  });

  test('a converted basis is reported so the UI can say so', () {
    final r = labelReadFromJson({
      'per_100g': {'kcal': 200},
      'basis': 'converted',
    });
    expect(r.basis, LabelBasis.converted);
  });

  test('no numbers at all reads as unknown, whatever basis claims', () {
    final r = labelReadFromJson({'name': 'X', 'basis': 'printed'});
    expect(r.basis, LabelBasis.unknown);
    expect(r.hasAnything, isTrue, reason: 'the name alone is worth showing');
  });

  test('a serving with no weight, or a silly one, is dropped', () {
    expect(labelReadFromJson({'serving': {'label': '1 dl'}}).serving, isNull);
    expect(
        labelReadFromJson({
          'serving': {'label': '1 dl', 'grams': 99999}
        }).serving,
        isNull);
  });

  test('not_a_product short-circuits everything', () {
    final r = labelReadFromJson({'not_a_product': true, 'name': 'Vaseline'});
    expect(r.notAProduct, isTrue);
    expect(r.hasAnything, isFalse);
    expect(r.name, isNull);
  });

  test('garbage never throws — it reads as nothing', () {
    expect(labelReadFromJson({}).hasAnything, isFalse);
    expect(labelReadFromJson({'per_100g': 'nope'}).values, isEmpty);
    expect(labelReadFromJson({'name': 42}).name, isNull);
    expect(labelReadFromJson({'serving': 'big'}).serving, isNull);
    expect(labelReadFromJson({'unreadable': 'salt'}).unreadable, isEmpty);
    expect(labelReadFromJson({'confidence': 7}).confidence, isNull);
  });

  test('unreadable fields survive — they are what the person must check', () {
    final r = labelReadFromJson({
      'per_100g': {'kcal': 100},
      'unreadable': ['sugars', 'salt', 42],
    });
    expect(r.unreadable, ['sugars', 'salt']);
  });
}
