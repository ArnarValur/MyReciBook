// The diary over time — every number a pile of day files already contains,
// worked out on the phone and nowhere else. Pure Dart: no Flutter imports in
// domain/, so all of it is testable without a widget tree.
//
// TWO RULES SHAPE EVERY LINE BELOW.
//
// Blank means "not measured", never zero — the diary's honesty rule carried
// into statistics. A nutrient nobody logged on Tuesday must not drag Tuesday
// into its average as a 0; it must not be in that average at all. So every
// average carries the count of days it was actually measured on, and the UI
// draws that count as coverage.
//
// Numbers state, never scold. "178 of 239" is a count beside the days that
// were available to log, not a score out of a target. Nothing here computes a
// percentage of compliance, a badge, or a "you missed N days".
//
// Future days are ignored throughout. The diary lets you plan tomorrow's
// breakfast; a trend of what you ate must not count food nobody has eaten.

import 'diary.dart';
import 'product.dart';

/// The five zoom levels of the Trends screen.
enum TrendRange { week, month, threeMonths, sixMonths, year }

/// What one chart column covers. A year of 365 columns is a smear, so the
/// wider ranges group — and a grouped column averages per LOGGED day rather
/// than totalling, or a month you logged thirty times towers over a month you
/// logged five times for a reason that has nothing to do with eating.
enum TrendBucketUnit { day, week, month }

extension TrendRangeLabel on TrendRange {
  /// The segmented control's own text.
  String get label => switch (this) {
        TrendRange.week => 'W',
        TrendRange.month => 'M',
        TrendRange.threeMonths => '3M',
        TrendRange.sixMonths => '6M',
        TrendRange.year => 'Y',
      };

  /// Day-resolution ranges get the micros ledger — the coverage dots need one
  /// dot per day to mean anything. The zoomed-out ones get the records ledger
  /// instead, where the chart matters less than what it all adds up to.
  bool get showsMicros => this == TrendRange.week || this == TrendRange.month;
}

/// The dates a range covers, anchored on the calendar rather than on a
/// trailing count of days: "this week", "August", "2026". The year view draws
/// September to December as empty stubs, which only makes sense if the window
/// is the calendar year — so the same anchoring is used all the way down.
class TrendWindow {
  /// First and last date of the period, YYYY-MM-DD. [end] may be in the
  /// future — that is what draws the stubs.
  final String start;
  final String end;

  /// Last date that has actually happened: min(end, today).
  final String last;

  final TrendBucketUnit unit;

  /// "24–30 Aug", "August 2026", "2026" — the caption beside the headline.
  final String caption;

  const TrendWindow({
    required this.start,
    required this.end,
    required this.last,
    required this.unit,
    required this.caption,
  });
}

/// One column of the energy chart.
class TrendBucket {
  /// First and last date this column covers, inclusive.
  final String start;
  final String end;

  /// The axis label, or '' where the axis is deliberately sparse — a month of
  /// 31 columns cannot carry 31 numbers.
  final String label;

  /// Energy for the column: the day's total for a day column, the average per
  /// logged day for a week or month column. Null when nothing was logged,
  /// which draws as a baseline stub — never as a bar of height zero.
  final double? kcal;

  final int daysLogged;

  /// Days in this column that have happened. Zero means the whole column is
  /// still in the future.
  final int daysAvailable;

  /// True for the column today falls in — today's bar renders faded because
  /// the day is not over, and so does the current month's.
  final bool isCurrent;

  const TrendBucket({
    required this.start,
    required this.end,
    required this.label,
    required this.kcal,
    required this.daysLogged,
    required this.daysAvailable,
    required this.isCurrent,
  });

  /// Nothing here has happened yet.
  bool get isFuture => daysAvailable == 0;
}

/// One slice of "where the energy came from". [share] is the slice's part of
/// the energy the MEASURED macros account for — it is a split, so the slices
/// sum to 1 by construction.
class MacroShare {
  final String key;
  final double gramsPerDay;
  final double share;
  final int daysMeasured;

  const MacroShare({
    required this.key,
    required this.gramsPerDay,
    required this.share,
    required this.daysMeasured,
  });
}

/// One row of the micros ledger. [average] is over [daysMeasured] days ONLY —
/// the days that carried the field. [coverage] is one flag per day that has
/// happened in the window, oldest first: the dots.
class MicroRow {
  final String key;
  final double average;
  final int daysMeasured;
  final int daysAvailable;
  final List<bool> coverage;

  const MicroRow({
    required this.key,
    required this.average,
    required this.daysMeasured,
    required this.daysAvailable,
    required this.coverage,
  });
}

/// A food and how many times it was logged.
class FoodTally {
  final String name;
  final int count;

  const FoodTally(this.name, this.count);
}

/// The ledger of records — the surprise of the zoomed-out view. Every field is
/// a count or a measurement; none of them is a verdict.
class DiaryRecords {
  final int daysLogged;
  final int daysAvailable;

  /// Longest run of consecutive logged days inside the window. Bounded by the
  /// window on purpose: "longest streak in 2026" is a fact about 2026.
  final int longestStreak;

  /// The biggest day and when it was. Null when nothing in the window carries
  /// an energy value.
  final double? highestKcal;
  final String? highestDate;

  /// Most-logged food (products and quick adds) and most-logged recipe, kept
  /// apart because they answer different questions.
  final FoodTally? topFood;
  final FoodTally? topRecipe;

  const DiaryRecords({
    required this.daysLogged,
    required this.daysAvailable,
    required this.longestStreak,
    this.highestKcal,
    this.highestDate,
    this.topFood,
    this.topRecipe,
  });
}

/// Everything the Trends screen draws, for one range.
class DiaryStats {
  final TrendRange range;
  final TrendWindow window;
  final List<TrendBucket> buckets;

  /// Average energy per LOGGED day. Null when no day in the window carries
  /// one — a range with nothing in it says so instead of showing 0 kcal.
  final double? averageKcal;

  /// Fat / carbs / protein, in that order, dropping any that no day measured.
  final List<MacroShare> macros;

  /// Every other nutrient field the logged days actually carry, in label
  /// order, then anything unrecognised alphabetically.
  final List<MicroRow> micros;

  final DiaryRecords records;

  const DiaryStats({
    required this.range,
    required this.window,
    required this.buckets,
    required this.averageKcal,
    required this.macros,
    required this.micros,
    required this.records,
  });

  int get daysLogged => records.daysLogged;
  int get daysAvailable => records.daysAvailable;

  /// Nothing to draw a chart from.
  bool get isEmpty => records.daysLogged == 0;

  /// The tallest column, for scaling the bars. Null when nothing is logged.
  double? get peakKcal {
    double? peak;
    for (final bucket in buckets) {
      final value = bucket.kcal;
      if (value != null && (peak == null || value > peak)) peak = value;
    }
    return peak;
  }
}

/// The three macros the energy split is made of, and their Atwater factors —
/// the same numbers the goal screen types its percentages out of.
const _macroKeys = ['fat', 'carbs', 'protein'];
const _perGram = {'fat': 9.0, 'carbs': 4.0, 'protein': 4.0};

/// Fields the ledger never lists: energy is the headline and the three macros
/// are the split above it, so repeating them as rows would be noise.
const _ledgerSkips = {'kcal', 'energy_kj', 'fat', 'carbs', 'protein'};

/// Ledger order — a nutrition label's own order, so the ledger reads down the
/// way the packet does. Deliberately a local list rather than a peek into
/// nutrient_display's private map: this is a display ORDER decision and the
/// two are free to disagree. Anything not here sorts alphabetically after.
const _ledgerOrder = [
  'saturated_fat',
  'monounsaturated_fat',
  'polyunsaturated_fat',
  'trans_fat',
  'cholesterol',
  'sugars',
  'added_sugars',
  'starch',
  'polyols',
  'fiber',
  'salt',
  'sodium',
  'alcohol',
  'caffeine',
];

/// The whole screen's numbers, from a list of day files.
///
/// [days] may hold anything — days outside the window, empty days, days in the
/// future. All three are dropped here rather than at the call site, so a
/// caller that over-fetches is never a wrong number.
DiaryStats computeDiaryStats({
  required TrendRange range,
  required DateTime today,
  required Iterable<DiaryDay> days,
}) {
  final window = trendWindow(range, today);
  final dates = datesInRange(window.start, window.last);

  final byDate = <String, DiaryDay>{};
  for (final day in days) {
    if (day.isEmpty) continue;
    if (day.date.compareTo(window.start) < 0) continue;
    if (day.date.compareTo(window.last) > 0) continue;
    byDate[day.date] = day;
  }

  // One pass over the files; every card below is cut from these totals.
  final totals = <String, Nutriments>{
    for (final entry in byDate.entries) entry.key: entry.value.total,
  };

  return DiaryStats(
    range: range,
    window: window,
    buckets: _buckets(window, totals, diaryDate(today)),
    averageKcal: _averageKcal(totals.values),
    macros: _macroShares(totals.values),
    micros: _micros(dates, totals),
    records: _records(dates, byDate, totals),
  );
}

/// The calendar period a range covers, anchored on [today].
TrendWindow trendWindow(TrendRange range, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  final todayKey = diaryDate(t);

  switch (range) {
    case TrendRange.week:
      final monday = _shift(t, -(t.weekday - 1));
      return _window(monday, _shift(monday, 6), todayKey, TrendBucketUnit.day,
          _spanCaption(monday, _shift(monday, 6)));
    case TrendRange.month:
      final first = DateTime(t.year, t.month, 1);
      return _window(first, DateTime(t.year, t.month + 1, 0), todayKey,
          TrendBucketUnit.day, '${_monthNames[t.month - 1]} ${t.year}');
    case TrendRange.threeMonths:
    case TrendRange.sixMonths:
      // Week columns, so the window is week-aligned too: thirteen or
      // twenty-six whole weeks ending with the one we are in. Anchoring on the
      // 1st of a month instead would leave a ragged half week at each edge.
      final weeks = range == TrendRange.threeMonths ? 13 : 26;
      final sunday = _shift(t, 7 - t.weekday);
      final monday = _shift(sunday, -(weeks * 7 - 1));
      return _window(monday, sunday, todayKey, TrendBucketUnit.week,
          _spanCaption(monday, sunday));
    case TrendRange.year:
      return _window(DateTime(t.year, 1, 1), DateTime(t.year, 12, 31), todayKey,
          TrendBucketUnit.month, '${t.year}');
  }
}

TrendWindow _window(DateTime start, DateTime end, String todayKey,
    TrendBucketUnit unit, String caption) {
  final startKey = diaryDate(start);
  final endKey = diaryDate(end);
  return TrendWindow(
    start: startKey,
    end: endKey,
    // A window entirely in the past ends where it ends; the one we are living
    // in ends today.
    last: endKey.compareTo(todayKey) <= 0 ? endKey : todayKey,
    unit: unit,
    caption: caption,
  );
}

List<TrendBucket> _buckets(
    TrendWindow window, Map<String, Nutriments> totals, String todayKey) {
  switch (window.unit) {
    case TrendBucketUnit.day:
      final dates = datesInRange(window.start, window.end);
      final crowded = dates.length > 14;
      return [
        for (final date in dates)
          _bucket(
            start: date,
            end: date,
            // A month cannot carry 31 numbers on a phone-wide axis, so it
            // carries the ones people look for: the 1st and every 5th.
            label: crowded
                ? (_dayOf(date) == 1 || _dayOf(date) % 5 == 0
                    ? '${_dayOf(date)}'
                    : '')
                : _weekdayInitials[DateTime.parse(date).weekday - 1],
            dates: [date],
            totals: totals,
            todayKey: todayKey,
          )
      ];
    case TrendBucketUnit.week:
      final out = <TrendBucket>[];
      final end = DateTime.parse(window.end);
      var cursor = DateTime.parse(window.start);
      var previousMonth = -1;
      while (!cursor.isAfter(end)) {
        final last = _shift(cursor, 6);
        // A label per week would be unreadable; one per month change reads as
        // a calendar without saying anything twice.
        final label = cursor.month == previousMonth
            ? ''
            : _monthInitials[cursor.month - 1];
        previousMonth = cursor.month;
        out.add(_bucket(
          start: diaryDate(cursor),
          end: diaryDate(last),
          label: label,
          dates: datesInRange(diaryDate(cursor), diaryDate(last)),
          totals: totals,
          todayKey: todayKey,
        ));
        cursor = _shift(cursor, 7);
      }
      return out;
    case TrendBucketUnit.month:
      final year = int.parse(window.start.substring(0, 4));
      final out = <TrendBucket>[];
      for (var month = 1; month <= 12; month++) {
        final first = diaryDate(DateTime(year, month, 1));
        final last = diaryDate(DateTime(year, month + 1, 0));
        out.add(_bucket(
          start: first,
          end: last,
          label: _monthInitials[month - 1],
          dates: datesInRange(first, last),
          totals: totals,
          todayKey: todayKey,
        ));
      }
      return out;
  }
}

TrendBucket _bucket({
  required String start,
  required String end,
  required String label,
  required List<String> dates,
  required Map<String, Nutriments> totals,
  required String todayKey,
}) {
  var available = 0;
  var logged = 0;
  var energy = 0.0;
  var energyDays = 0;
  for (final date in dates) {
    if (date.compareTo(todayKey) > 0) continue;
    available++;
    final total = totals[date];
    if (total == null) continue;
    logged++;
    final kcal = total.kcal;
    if (kcal != null) {
      energy += kcal;
      energyDays++;
    }
  }
  return TrendBucket(
    start: start,
    end: end,
    label: label,
    kcal: energyDays == 0 ? null : energy / energyDays,
    daysLogged: logged,
    daysAvailable: available,
    isCurrent: todayKey.compareTo(start) >= 0 && todayKey.compareTo(end) <= 0,
  );
}

double? _averageKcal(Iterable<Nutriments> totals) {
  var sum = 0.0;
  var count = 0;
  for (final total in totals) {
    final kcal = total.kcal;
    if (kcal == null) continue;
    sum += kcal;
    count++;
  }
  return count == 0 ? null : sum / count;
}

List<MacroShare> _macroShares(Iterable<Nutriments> totals) {
  final sums = <String, double>{};
  final counts = <String, int>{};
  for (final total in totals) {
    for (final key in _macroKeys) {
      final grams = total[key];
      if (grams == null) continue;
      sums[key] = (sums[key] ?? 0) + grams;
      counts[key] = (counts[key] ?? 0) + 1;
    }
  }
  final perDay = <String, double>{
    for (final key in _macroKeys)
      if (counts[key] != null) key: sums[key]! / counts[key]!,
  };
  // The split is of the energy the MEASURED macros account for, not of the
  // day's calories: a day whose quick add carried kcal but no macros would
  // otherwise leave a silent gap in the bar that reads as a fourth macro.
  var energy = 0.0;
  perDay.forEach((key, grams) => energy += grams * _perGram[key]!);
  if (energy <= 0) return const [];
  return [
    for (final key in _macroKeys)
      if (perDay[key] != null)
        MacroShare(
          key: key,
          gramsPerDay: perDay[key]!,
          share: perDay[key]! * _perGram[key]! / energy,
          daysMeasured: counts[key]!,
        )
  ];
}

List<MicroRow> _micros(List<String> dates, Map<String, Nutriments> totals) {
  final sums = <String, double>{};
  final counts = <String, int>{};
  final measuredOn = <String, Set<String>>{};
  totals.forEach((date, total) {
    total.values.forEach((key, value) {
      if (_ledgerSkips.contains(key)) return;
      sums[key] = (sums[key] ?? 0) + value;
      counts[key] = (counts[key] ?? 0) + 1;
      (measuredOn[key] ??= <String>{}).add(date);
    });
  });
  // All-zero rows say nothing: "the days that measured it measured none" is
  // a whole screen of "Calcium 0 g" the moment one product carries explicit
  // zeros (Arnar 2026-08-27). A field with any measured amount still shows.
  final keys = [
    for (final key in sums.keys)
      if (sums[key]! > 0) key
  ]..sort(_byLedgerOrder);
  return [
    for (final key in keys)
      MicroRow(
        key: key,
        average: sums[key]! / counts[key]!,
        daysMeasured: counts[key]!,
        daysAvailable: dates.length,
        coverage: [for (final date in dates) measuredOn[key]!.contains(date)],
      )
  ];
}

int _byLedgerOrder(String a, String b) {
  final ia = _ledgerOrder.indexOf(a);
  final ib = _ledgerOrder.indexOf(b);
  if (ia >= 0 && ib >= 0) return ia.compareTo(ib);
  if (ia >= 0) return -1;
  if (ib >= 0) return 1;
  return a.compareTo(b);
}

DiaryRecords _records(List<String> dates, Map<String, DiaryDay> byDate,
    Map<String, Nutriments> totals) {
  var longest = 0;
  var run = 0;
  for (final date in dates) {
    if (byDate.containsKey(date)) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }

  double? highest;
  String? highestDate;
  totals.forEach((date, total) {
    final kcal = total.kcal;
    if (kcal == null) return;
    // Ties keep the earlier day: a record that moves when nothing changed is
    // not a record.
    if (highest == null || kcal > highest!) {
      highest = kcal;
      highestDate = date;
    } else if (kcal == highest && date.compareTo(highestDate!) < 0) {
      highestDate = date;
    }
  });

  final foods = <String, _Tally>{};
  final recipes = <String, _Tally>{};
  for (final day in byDate.values) {
    for (final meal in day.meals) {
      for (final entry in meal.entries) {
        final into = entry.source == DiarySources.recipe ? recipes : foods;
        // Keyed on what it was logged FROM, so two spellings of one product
        // still count as one food; a quick add falls back to its name.
        final key = entry.ref ?? entry.name.toLowerCase();
        (into[key] ??= _Tally(entry.name)).count++;
      }
    }
  }

  return DiaryRecords(
    daysLogged: byDate.length,
    daysAvailable: dates.length,
    longestStreak: longest,
    highestKcal: highest,
    highestDate: highestDate,
    topFood: _top(foods),
    topRecipe: _top(recipes),
  );
}

class _Tally {
  _Tally(this.name);
  final String name;
  int count = 0;
}

FoodTally? _top(Map<String, _Tally> tallies) {
  _Tally? best;
  for (final tally in tallies.values) {
    if (best == null ||
        tally.count > best.count ||
        // Alphabetical on a tie, so the same diary always names the same food.
        (tally.count == best.count && tally.name.compareTo(best.name) < 0)) {
      best = tally;
    }
  }
  return best == null ? null : FoodTally(best.name, best.count);
}

// --- dates ---

/// Every date from [start] to [end] inclusive, oldest first. Empty when the
/// range runs backwards.
List<String> datesInRange(String start, String end) {
  if (start.compareTo(end) > 0) return const [];
  final out = <String>[];
  final stop = DateTime.parse(end);
  var cursor = DateTime.parse(start);
  while (!cursor.isAfter(stop)) {
    out.add(diaryDate(cursor));
    cursor = _shift(cursor, 1);
  }
  return out;
}

/// Days added through the constructor, not through a Duration: an hour of
/// summer time going away must never turn "+1 day" into the same date twice.
DateTime _shift(DateTime from, int days) =>
    DateTime(from.year, from.month, from.day + days);

int _dayOf(String date) => int.parse(date.substring(8, 10));

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December'
];

const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec'
];

const _monthInitials = [
  'J',
  'F',
  'M',
  'A',
  'M',
  'J',
  'J',
  'A',
  'S',
  'O',
  'N',
  'D'
];

const _weekdayInitials = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// "24–30 Aug" inside one month, "31 Aug – 6 Sep" across two, with years once
/// the span crosses one.
String _spanCaption(DateTime start, DateTime end) {
  final sameYear = start.year == end.year;
  if (sameYear && start.month == end.month) {
    return '${start.day}–${end.day} ${_monthShort[end.month - 1]}';
  }
  String side(DateTime d) =>
      '${d.day} ${_monthShort[d.month - 1]}${sameYear ? '' : ' ${d.year}'}';
  return '${side(start)} – ${side(end)}';
}

/// "1,887" — thousands grouped, the way the headline reads.
String groupedNumber(double value) {
  final digits = value.round().abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// "17 May" — the date beside a record.
String shortDate(String date) {
  final d = DateTime.parse(date);
  return '${d.day} ${_monthShort[d.month - 1]}';
}
