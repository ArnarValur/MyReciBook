// The Trends screen end to end: reach it from the diary's date row, then walk
// all five ranges in both themes on a phone-sized surface.
//
// The numbers are proved in test/domain/diary_stats_test.dart, which is where
// the work is. This file proves the SCREEN — that every range draws, in light
// and in dark, at 360dp wide, without a single overflow.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/ui/diary/diary_model.dart';
import 'package:myrecibook/ui/diary/diary_tab.dart';
import 'package:myrecibook/ui/diary/trends_screen.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

/// The diary in a map — real file IO never completes inside testWidgets.
class _MemoryDiaryStore implements DiaryStore {
  final days = <String, DiaryDay>{};

  @override
  Future<DiaryDay> load(String date) async =>
      days[date] ?? DiaryDay.empty(date);

  @override
  Future<DiaryDay> save(DiaryDay day) async => days[day.date] = day;

  @override
  Future<List<String>> loggedDates() async =>
      days.keys.toList()..sort((a, b) => b.compareTo(a));

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) async =>
      const [];
}

/// Two hundred days back, logged every third day: gaps, a partial current
/// month, and a nutrient (fibre) that only half the days measured.
DiaryStore seeded() {
  final store = _MemoryDiaryStore();
  final now = DateTime.now();
  for (var back = 0; back < 200; back += 3) {
    final date = diaryDate(DateTime(now.year, now.month, now.day - back));
    store.days[date] = DiaryDay.empty(date).addEntry(
      'Lunch',
      DiaryEntry(
        id: date,
        name: 'Havregryn',
        source: DiarySources.product,
        ref: 'oats',
        quantity: 1,
        perServing: Nutriments.fromMap({
          'kcal': 1200 + back * 3.0,
          'fat': 40,
          'carbs': 150,
          'protein': 70,
          'saturated_fat': 12,
          if (back % 2 == 0) 'fiber': 9,
          'salt': 3,
          'sodium': 1.2,
        }),
      ),
    );
  }
  return store;
}

void main() {
  /// A Samsung-shaped window, because 800×600 hides every overflow a phone
  /// would show.
  void phoneSized(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Widget app(DiaryStore store, ThemeData theme, Widget home) =>
      ChangeNotifierProvider<DiaryModel>(
        create: (_) => DiaryModel(store),
        child: MaterialApp(theme: theme, home: home),
      );

  testWidgets('every range draws, in light and in dark', (tester) async {
    phoneSized(tester);
    final store = seeded();
    for (final theme in [rbLightTheme(), rbDarkTheme()]) {
      await tester.pumpWidget(app(store, theme, const TrendsScreen()));
      await tester.pumpAndSettle();
      for (final range in ['W', 'M', '3M', '6M', 'Y']) {
        // .first: the axis spells weekdays with the same letters.
        await tester.tap(find.text(range).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: range);
      }
      // The zoomed-out view is the ledger of records, and it states counts.
      expect(find.text('Days logged'), findsOneWidget);
      expect(find.text('Longest streak'), findsOneWidget);
      expect(find.textContaining('Nothing leaves it.'), findsOneWidget);
    }
  });

  testWidgets('an empty diary says so instead of drawing a chart',
      (tester) async {
    phoneSized(tester);
    await tester.pumpWidget(
        app(_MemoryDiaryStore(), rbLightTheme(), const TrendsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget); // no average is invented
    expect(find.textContaining('nothing logged'), findsOneWidget);
    expect(find.text('No days logged in this range yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the diary date row opens it', (tester) async {
    phoneSized(tester);
    await tester
        .pumpWidget(app(seeded(), rbLightTheme(), const DiaryTab()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Trends'));
    await tester.pumpAndSettle();

    expect(find.text('Where the energy came from'.toUpperCase()),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
