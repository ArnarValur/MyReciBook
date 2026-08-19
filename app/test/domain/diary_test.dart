// The diary's arithmetic and its file contract. The rule under test
// everywhere here: an entry's numbers are a SNAPSHOT — nothing in this file
// may ever need a product to compute a total.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';

Product oats() => Product(
      schemaVersion: 1,
      barcode: '7311070003417',
      name: 'Havregryn',
      brand: 'Axa',
      source: 'off',
      nutriments: Nutriments(kcal: 370, fat: 7, carbs: 59, protein: 13),
      servings: const [Serving(label: '1 dl', grams: 35)],
      defaultServing: 0,
    );

DiaryEntry oatsEntry({double quantity = 2, String id = 'e1'}) =>
    entryFromProduct(oats(), oats().servings.first,
        quantity: quantity, id: id);

void main() {
  group('serving options', () {
    test('100 g is always offered, on top of the pack portion', () {
      final options = oats().servingOptions;
      expect(options.map((s) => s.label), ['1 dl', '100 g']);
      expect(oats().preferredServing.label, '1 dl');
    });

    test('a product with no servings is still loggable', () {
      final bare = Product(
          schemaVersion: 1, barcode: '1', name: 'Banana', source: 'manual');
      expect(bare.servingOptions.single.grams, 100);
      expect(bare.preferredServing.grams, 100);
    });

    test('a product that only lists 100 g does not get it twice', () {
      final p = Product(
        schemaVersion: 1,
        barcode: '1',
        name: 'Flour',
        source: 'manual',
        servings: const [Serving(label: '100 g', grams: 100)],
      );
      expect(p.servingOptions.length, 1);
    });

    test('an out-of-range default falls back to the first option', () {
      final p = oats().copyWith(defaultServing: 9);
      expect(p.preferredServing.label, '1 dl');
    });

    test('a typed gram amount becomes a portion', () {
      expect(Serving.grams(125).label, '125 g');
      expect(Serving.grams(37.5).label, '37.5 g');
    });
  });

  group('logging a product', () {
    test('per-serving is per-100g scaled by the portion weight', () {
      final entry = oatsEntry(quantity: 1);
      expect(entry.perServing.kcal, closeTo(129.5, 0.001)); // 370 * 0.35
      expect(entry.perServing.protein, closeTo(4.55, 0.001));
      expect(entry.servingGrams, 35);
    });

    test('the row total is per-serving times quantity', () {
      final entry = oatsEntry(quantity: 2);
      expect(entry.total.kcal, closeTo(259, 0.001));
      expect(entry.grams, 70);
    });

    test('quantity edits never drift — per-serving is the stored fact', () {
      var entry = oatsEntry(quantity: 2);
      for (final q in [1.0, 3.0, 0.5, 2.0]) {
        entry = entry.copyWith(quantity: q);
      }
      expect(entry.perServing.kcal, closeTo(129.5, 0.001));
      expect(entry.total.kcal, closeTo(259, 0.001));
    });

    test('the ref is kept for re-logging, not for arithmetic', () {
      expect(oatsEntry().ref, '7311070003417');
      expect(oatsEntry().source, DiarySources.product);
    });

    test('a product with no nutriments logs as an empty snapshot, not a crash',
        () {
      final blank = Product(
          schemaVersion: 1, barcode: '9', name: 'Mystery', source: 'manual');
      final entry = entryFromProduct(blank, blank.preferredServing,
          quantity: 1, id: 'x');
      expect(entry.total.values, isEmpty);
    });

    test('the row subtitle reads the way MFP prints it', () {
      expect(oatsEntry(quantity: 1).servingSummary, '1 dl');
      expect(oatsEntry(quantity: 2).servingSummary, '2 × 1 dl');
      expect(oatsEntry(quantity: 1.5).servingSummary, '1.5 × 1 dl');
    });
  });

  group('quick add', () {
    test('carries calories with no product behind it', () {
      final entry = quickAddEntry(id: 'q1', kcal: 250);
      expect(entry.total.kcal, 250);
      expect(entry.ref, isNull);
      expect(entry.grams, isNull);
      expect(entry.source, DiarySources.quick);
    });
  });

  group('day maths', () {
    test('the day totals every meal', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Breakfast', oatsEntry(quantity: 1, id: 'a'))
          .addEntry('Lunch', quickAddEntry(id: 'b', kcal: 600));
      expect(day.total.kcal, closeTo(729.5, 0.001));
      expect(day.entryCount, 2);
    });

    test('a nutrient only one food carries still totals', () {
      final withIron = DiaryEntry(
        id: 'i',
        name: 'Spinach',
        source: DiarySources.product,
        quantity: 1,
        perServing: const Nutriments.fromMap({'kcal': 23, 'iron': 0.0027}),
      );
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Lunch', withIron)
          .addEntry('Lunch', quickAddEntry(id: 'q', kcal: 100));
      expect(day.total.kcal, 123);
      expect(day.total['iron'], closeTo(0.0027, 1e-9));
    });

    test('an empty day totals nothing rather than throwing', () {
      expect(DiaryDay.empty('2026-08-19').total.values, isEmpty);
      expect(DiaryDay.empty('2026-08-19').isEmpty, isTrue);
    });
  });

  group('day edits', () {
    test('adding creates the meal in log order', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Dinner', oatsEntry(id: 'a'))
          .addEntry('Breakfast', oatsEntry(id: 'b'))
          .addEntry('Dinner', oatsEntry(id: 'c'));
      expect(day.meals.map((m) => m.name), ['Dinner', 'Breakfast']);
      expect(day.meal('Dinner')!.entries.map((e) => e.id), ['a', 'c']);
    });

    test('removing the last entry removes the meal too', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Lunch', oatsEntry(id: 'a'))
          .removeEntry('a');
      expect(day.meals, isEmpty);
      expect(day.isEmpty, isTrue);
    });

    test('updating keeps the row where it was', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Lunch', oatsEntry(id: 'a'))
          .addEntry('Lunch', oatsEntry(id: 'b'));
      final edited = day
          .updateEntry(day.meal('Lunch')!.entries.first.copyWith(quantity: 4));
      expect(edited.meal('Lunch')!.entries.map((e) => e.id), ['a', 'b']);
      expect(edited.meal('Lunch')!.entries.first.quantity, 4);
    });

    test('moving an entry re-homes it without duplicating', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Lunch', oatsEntry(id: 'a'))
          .moveEntry('a', 'Dinner');
      expect(day.meal('Lunch'), isNull);
      expect(day.meal('Dinner')!.entries.single.id, 'a');
      expect(day.entryCount, 1);
    });

    test('moving an id that is not there changes nothing', () {
      final day =
          DiaryDay.empty('2026-08-19').addEntry('Lunch', oatsEntry(id: 'a'));
      expect(day.moveEntry('nope', 'Dinner').entryCount, 1);
    });

    test('copying a meal to another day gives the copies their own ids', () {
      final monday = DiaryDay.empty('2026-08-17')
          .addEntry('Breakfast', oatsEntry(id: 'a'))
          .addEntry('Breakfast', quickAddEntry(id: 'b', kcal: 90));
      final tuesday = DiaryDay.empty('2026-08-18')
          .copyMealFrom(monday, 'Breakfast', newIds: (i) => 'copy$i');
      expect(tuesday.meal('Breakfast')!.entries.map((e) => e.id),
          ['copy0', 'copy1']);
      expect(tuesday.total.kcal, monday.total.kcal);
      // Deleting the original must not touch the copy.
      expect(monday.removeEntry('a').entryCount, 1);
      expect(tuesday.entryCount, 2);
    });

    test('copying a meal that does not exist is a no-op', () {
      final empty = DiaryDay.empty('2026-08-17');
      expect(
          DiaryDay.empty('2026-08-18')
              .copyMealFrom(empty, 'Breakfast', newIds: (i) => 'c$i')
              .isEmpty,
          isTrue);
    });
  });

  group('file contract', () {
    test('a day round-trips', () {
      final day = DiaryDay.empty('2026-08-19')
          .addEntry('Breakfast', oatsEntry(id: 'a'))
          .addEntry('Snacks', quickAddEntry(id: 'q', kcal: 120));
      final back = DiaryDay.fromJson(day.toJson());
      expect(back.date, '2026-08-19');
      expect(back.entryCount, 2);
      expect(back.total.kcal, closeTo(day.total.kcal!, 1e-9));
      expect(back.meal('Breakfast')!.entries.single.servingLabel, '1 dl');
    });

    test('a quick add does not gain empty product fields', () {
      final json = quickAddEntry(id: 'q', kcal: 120).toJson();
      expect(json.containsKey('ref'), isFalse);
      expect(json.containsKey('serving_grams'), isFalse);
      expect(json.containsKey('brand'), isFalse);
    });

    test('validation rejects what must never be written', () {
      expect(diaryProblems(DiaryDay.empty('2026-08-19').toJson()), isEmpty);
      expect(diaryProblems({'schema_version': 1}), contains('missing:date'));
      expect(diaryProblems({'schema_version': 1, 'date': '19-08-2026'}),
          contains('bad date'));
      expect(diaryProblems({'schema_version': 2, 'date': '2026-08-19'}),
          contains('unknown schema_version 2'));
      expect(
          diaryProblems({
            'schema_version': 1,
            'date': '2026-08-19',
            'meals': [
              {
                'name': 'Lunch',
                'entries': [
                  {'name': 'no id', 'quantity': 1}
                ]
              }
            ]
          }),
          contains('entry without an id'));
    });

    test('a file from a future build reads what it can', () {
      final back = DiaryDay.fromJson({
        'schema_version': 1,
        'date': '2026-08-19',
        'meals': [
          {
            'name': 'Lunch',
            'entries': [
              {
                'id': 'x',
                'name': 'Soup',
                'source': 'restaurant_menu', // a kind we don't know yet
                'quantity': 1,
                'per_serving': {'kcal': 210},
                'mood': 'excellent', // a field we don't know yet
              }
            ]
          }
        ]
      });
      expect(back.total.kcal, 210);
      expect(back.meal('Lunch')!.entries.single.source, 'restaurant_menu');
    });
  });

  group('dates', () {
    test('only real calendar days are diary dates', () {
      expect(isDiaryDate('2026-08-19'), isTrue);
      expect(isDiaryDate('2026-02-29'), isFalse); // 2026 is not a leap year
      expect(isDiaryDate('2026-13-01'), isFalse);
      expect(isDiaryDate('2026-8-9'), isFalse);
      expect(isDiaryDate('../../etc/passwd'), isFalse);
      expect(isDiaryDate(''), isFalse);
    });

    test('a DateTime becomes its local day key', () {
      expect(diaryDate(DateTime(2026, 8, 9, 23, 30)), '2026-08-09');
      expect(diaryDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
