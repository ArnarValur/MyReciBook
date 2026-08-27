// diary_stats — the rules the Trends screen is only as honest as.
//
// The one under everything: blank means "not measured", never zero. A day that
// nobody logged must not enter an average; a nutrient only some days carried
// must average over those days and SAY how many they were.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/diary_stats.dart';
import 'package:myrecibook/domain/product.dart';

/// A day with one quick-add-shaped entry carrying whatever nutrients are
/// given — the shortest way to make a day worth a number.
DiaryDay day(String date, Map<String, double> nutrients,
        {String name = 'Something',
        String source = DiarySources.quick,
        String? ref,
        String meal = 'Lunch'}) =>
    DiaryDay.empty(date).addEntry(
      meal,
      DiaryEntry(
        id: '$date-$name',
        name: name,
        source: source,
        ref: ref,
        quantity: 1,
        perServing: Nutriments.fromMap(nutrients),
      ),
    );

void main() {
  // A Thursday. Its week is Mon 24 – Sun 30 August 2026.
  final thursday = DateTime(2026, 8, 27, 12, 30);

  group('the window', () {
    test('the week is the calendar week today falls in', () {
      final w = trendWindow(TrendRange.week, thursday);
      expect(w.start, '2026-08-24');
      expect(w.end, '2026-08-30');
      // It ends TODAY, not on Sunday: Friday has not happened.
      expect(w.last, '2026-08-27');
      expect(w.caption, '24–30 Aug');
      expect(w.unit, TrendBucketUnit.day);
    });

    test('the month is the calendar month, the year the calendar year', () {
      final m = trendWindow(TrendRange.month, thursday);
      expect(m.start, '2026-08-01');
      expect(m.end, '2026-08-31');
      expect(m.caption, 'August 2026');

      final y = trendWindow(TrendRange.year, thursday);
      expect(y.start, '2026-01-01');
      expect(y.end, '2026-12-31');
      expect(y.last, '2026-08-27');
      expect(y.caption, '2026');
      expect(y.unit, TrendBucketUnit.month);
    });

    test('3M and 6M are whole weeks, so the columns never start ragged', () {
      final three = trendWindow(TrendRange.threeMonths, thursday);
      expect(three.end, '2026-08-30'); // this week's Sunday
      expect(datesInRange(three.start, three.end).length, 13 * 7);
      expect(three.unit, TrendBucketUnit.week);

      final six = trendWindow(TrendRange.sixMonths, thursday);
      expect(datesInRange(six.start, six.end).length, 26 * 7);
    });
  });

  group('the week chart', () {
    test('one bar per day, today faded, tomorrow a stub', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {'kcal': 2000}),
          day('2026-08-25', {'kcal': 1600}),
          day('2026-08-27', {'kcal': 400}), // today, still going
        ],
      );

      expect(stats.buckets.length, 7);
      expect(stats.buckets.map((b) => b.label).toList(),
          ['M', 'T', 'W', 'T', 'F', 'S', 'S']);

      // Monday and Tuesday are done and logged.
      expect(stats.buckets[0].kcal, 2000);
      expect(stats.buckets[0].isCurrent, isFalse);

      // Wednesday happened and was NOT logged — no bar, and it is not a zero.
      expect(stats.buckets[2].kcal, isNull);
      expect(stats.buckets[2].daysAvailable, 1);
      expect(stats.buckets[2].isFuture, isFalse);

      // Thursday is today: a bar, but the day is not over.
      expect(stats.buckets[3].kcal, 400);
      expect(stats.buckets[3].isCurrent, isTrue);

      // Friday onward has not happened at all.
      expect(stats.buckets[4].isFuture, isTrue);
      expect(stats.buckets[6].isFuture, isTrue);
    });

    test('the average is per LOGGED day, never per calendar day', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {'kcal': 2000}),
          day('2026-08-25', {'kcal': 1600}),
        ],
      );
      // Two logged days out of four elapsed: 1800, not 900.
      expect(stats.averageKcal, 1800);
      expect(stats.daysLogged, 2);
      expect(stats.daysAvailable, 4);
    });

    test('days outside the window and days in the future are dropped', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-23', {'kcal': 9999}), // last week
          day('2026-08-26', {'kcal': 1000}),
          day('2026-08-29', {'kcal': 9999}), // planned Saturday
        ],
      );
      expect(stats.daysLogged, 1);
      expect(stats.averageKcal, 1000);
      expect(stats.records.highestKcal, 1000);
    });
  });

  group('the macro split', () {
    test('splits the energy the measured macros account for', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24',
              {'kcal': 1900, 'fat': 67, 'carbs': 240, 'protein': 80}),
        ],
      );
      final split = {for (final s in stats.macros) s.key: s};
      expect(split.keys, ['fat', 'carbs', 'protein']);
      expect(split['fat']!.gramsPerDay, 67);
      // 603 / 4 / 1883 of the macro-derived energy.
      expect(split['fat']!.share, closeTo(0.320, 0.001));
      expect(split['carbs']!.share, closeTo(0.510, 0.001));
      expect(split['protein']!.share, closeTo(0.170, 0.001));
      // A split, so it is whole by construction.
      expect(stats.macros.fold<double>(0, (sum, s) => sum + s.share),
          closeTo(1, 1e-9));
    });

    test('a macro nobody measured is absent, not a zero slice', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {'kcal': 1000, 'carbs': 100, 'protein': 50}),
          day('2026-08-25', {'kcal': 1000, 'carbs': 200, 'protein': 50}),
        ],
      );
      expect(stats.macros.map((s) => s.key), ['carbs', 'protein']);
      expect(stats.macros.first.gramsPerDay, 150);
    });

    test('a range of quick adds with no macros has no split at all', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [day('2026-08-24', {'kcal': 700})],
      );
      expect(stats.macros, isEmpty);
    });
  });

  group('the micros ledger', () {
    test('a nutrient measured on some days averages over THOSE days', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {'kcal': 1000, 'fiber': 20}),
          day('2026-08-25', {'kcal': 1000}), // logged, no fibre on the label
          day('2026-08-26', {'kcal': 1000, 'fiber': 10}),
        ],
      );
      final fibre = stats.micros.singleWhere((r) => r.key == 'fiber');

      // 15, not 10: the day that did not measure it is not in the divisor.
      expect(fibre.average, 15);
      expect(fibre.daysMeasured, 2);
      // Four days have happened this week; two of them measured fibre.
      expect(fibre.daysAvailable, 4);
      expect(fibre.coverage, [true, false, true, false]);
    });

    test('energy and the three macros never appear as ledger rows', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {
            'kcal': 1000,
            'fat': 10,
            'carbs': 100,
            'protein': 40,
            'saturated_fat': 4,
            'salt': 2,
          })
        ],
      );
      expect(stats.micros.map((r) => r.key), ['saturated_fat', 'salt']);
    });

    test('rows come out in label order, unknown keys alphabetically after', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {
            'sodium': 1.6,
            'zinc': 0.01,
            'salt': 4.1,
            'sugars': 58,
            'fiber': 19,
            'saturated_fat': 24,
            'calcium': 0.118,
          })
        ],
      );
      expect(stats.micros.map((r) => r.key).toList(), [
        'saturated_fat',
        'sugars',
        'fiber',
        'salt',
        'sodium',
        'calcium',
        'zinc',
      ]);
    });
  });

  group('the records ledger', () {
    test('a streak breaks on a gap and the longest run wins', () {
      final stats = computeDiaryStats(
        range: TrendRange.year,
        today: thursday,
        days: [
          // Three in a row.
          day('2026-03-01', {'kcal': 1000}),
          day('2026-03-02', {'kcal': 1000}),
          day('2026-03-03', {'kcal': 1000}),
          // A gap, then four in a row — including across a month boundary.
          day('2026-04-28', {'kcal': 1000}),
          day('2026-04-29', {'kcal': 1000}),
          day('2026-04-30', {'kcal': 1000}),
          day('2026-05-01', {'kcal': 1000}),
          // A lone day.
          day('2026-07-14', {'kcal': 1000}),
        ],
      );
      expect(stats.records.longestStreak, 4);
      expect(stats.records.daysLogged, 8);
      // 2026 is not a leap year: Jan 1 to Aug 27 is 239 days.
      expect(stats.records.daysAvailable, 239);
    });

    test('an empty day file counts for nothing', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          DiaryDay.empty('2026-08-24'),
          day('2026-08-25', {'kcal': 1000}),
        ],
      );
      expect(stats.records.daysLogged, 1);
      expect(stats.records.longestStreak, 1);
    });

    test('highest day, most logged food and top recipe', () {
      final stats = computeDiaryStats(
        range: TrendRange.year,
        today: thursday,
        days: [
          day('2026-05-17', {'kcal': 3120}, name: 'Banana', ref: 'banana')
              .addEntry(
                  'Dinner',
                  DiaryEntry(
                    id: 'r1',
                    name: 'Havregryn classic',
                    source: DiarySources.recipe,
                    ref: 'recipe-oats',
                    quantity: 1,
                    perServing: Nutriments(kcal: 400),
                  )),
          day('2026-05-18', {'kcal': 1200}, name: 'Banana', ref: 'banana'),
          day('2026-05-19', {'kcal': 1100}, name: 'Banana', ref: 'banana'),
          day('2026-06-01', {'kcal': 900}, name: 'Skyr', ref: 'skyr'),
        ],
      );
      final records = stats.records;
      // 3120 + the recipe's 400 — the day total, as the diary sums it.
      expect(records.highestKcal, 3520);
      expect(records.highestDate, '2026-05-17');
      expect(records.topFood!.name, 'Banana');
      expect(records.topFood!.count, 3);
      // Recipes are counted apart from foods, so one recipe never wins "food".
      expect(records.topRecipe!.name, 'Havregryn classic');
      expect(records.topRecipe!.count, 1);
    });

    test('a month bar is the average per logged day, not the month total', () {
      final stats = computeDiaryStats(
        range: TrendRange.year,
        today: thursday,
        days: [
          day('2026-03-01', {'kcal': 2000}),
          day('2026-03-02', {'kcal': 1000}),
          // April logged once, at the same daily rate as March.
          day('2026-04-05', {'kcal': 1500}),
        ],
      );
      final march = stats.buckets[2];
      final april = stats.buckets[3];
      expect(march.kcal, 1500);
      expect(april.kcal, 1500);
      expect(march.daysLogged, 2);

      // August is the month we are in; September onward has not happened.
      expect(stats.buckets[7].isCurrent, isTrue);
      expect(stats.buckets[8].isFuture, isTrue);
      expect(stats.buckets[11].isFuture, isTrue);
    });
  });

  group('the honest edges', () {
    test('an empty diary draws no chart and claims no averages', () {
      for (final range in TrendRange.values) {
        final stats = computeDiaryStats(
          range: range,
          today: thursday,
          days: const [],
        );
        expect(stats.isEmpty, isTrue, reason: range.label);
        expect(stats.averageKcal, isNull, reason: range.label);
        expect(stats.peakKcal, isNull, reason: range.label);
        expect(stats.macros, isEmpty, reason: range.label);
        expect(stats.micros, isEmpty, reason: range.label);
        expect(stats.records.longestStreak, 0, reason: range.label);
        expect(stats.records.highestKcal, isNull, reason: range.label);
        expect(stats.records.topFood, isNull, reason: range.label);
        // The columns still exist — the axis is drawn, the bars are stubs.
        expect(stats.buckets, isNotEmpty, reason: range.label);
        expect(stats.buckets.every((b) => b.kcal == null), isTrue,
            reason: range.label);
      }
    });

    test('a single logged day is a single day, not a trend', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-26', {'kcal': 1750, 'fiber': 12})
        ],
      );
      expect(stats.averageKcal, 1750);
      expect(stats.peakKcal, 1750);
      expect(stats.daysLogged, 1);
      expect(stats.daysAvailable, 4);
      expect(stats.records.longestStreak, 1);
      expect(stats.micros.single.daysMeasured, 1);
      expect(stats.micros.single.coverage, [false, false, true, false]);
    });

    test('a day logged with no energy value is logged, but not an average', () {
      final stats = computeDiaryStats(
        range: TrendRange.week,
        today: thursday,
        days: [
          day('2026-08-24', {'fiber': 6}), // a label with no kcal on it
          day('2026-08-25', {'kcal': 1200}),
        ],
      );
      expect(stats.daysLogged, 2);
      expect(stats.averageKcal, 1200);
      expect(stats.buckets[0].kcal, isNull);
      expect(stats.buckets[0].daysLogged, 1);
    });
  });

  group('formatting', () {
    test('thousands are grouped the way the headline reads', () {
      expect(groupedNumber(1887), '1,887');
      expect(groupedNumber(3120.4), '3,120');
      expect(groupedNumber(999), '999');
      expect(groupedNumber(1000000), '1,000,000');
      expect(groupedNumber(0), '0');
    });

    test('a record date reads as a date', () {
      expect(shortDate('2026-05-17'), '17 May');
    });
  });
}
