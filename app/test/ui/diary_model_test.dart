// DiaryModel — the seam between the day screen and the day file. The rules
// under test: one day resident at a time, a null store degrades to memory,
// and a save that fails must not roll the screen back under the user's thumb.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/ui/diary/diary_model.dart';

Product oats() => Product(
      schemaVersion: 1,
      barcode: '1',
      name: 'Havregryn',
      source: 'off',
      nutriments: Nutriments(kcal: 370, protein: 13),
      servings: const [Serving(label: '1 dl', grams: 35)],
      defaultServing: 0,
    );

/// A store that refuses every write — the offline/grant-lost shape.
class _FailingStore implements DiaryStore {
  @override
  Future<DiaryDay> load(String date) async => DiaryDay.empty(date);
  @override
  Future<DiaryDay> save(DiaryDay day) async => throw StateError('nope');
  @override
  Future<List<String>> loggedDates() async => [];
  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) async =>
      [];
}

void main() {
  late Directory root;
  late LocalDiaryStore store;
  final cleanup = <Directory>[];
  final now = DateTime(2026, 8, 19, 9);

  setUp(() async {
    root = await Directory.systemTemp.createTemp('recibook_diary_model');
    cleanup.add(root);
    store = LocalDiaryStore(root);
  });

  tearDown(() async {
    for (final dir in cleanup) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    cleanup.clear();
  });

  DiaryModel model({DiaryStore? s}) =>
      DiaryModel(s ?? store, clock: () => now);

  test('opens on today with the default meal headings', () async {
    final m = model();
    expect(m.date, '2026-08-19');
    expect(m.isToday, isTrue);
    expect(m.mealNames, defaultMealNames);
  });

  test('logging a product writes the day and totals it', () async {
    final m = model();
    await m.ensureLoaded();
    await m.logProduct(oats(), oats().servings.first,
        meal: 'Breakfast', quantity: 2);

    expect(m.day.meal('Breakfast')!.entries.single.name, 'Havregryn');
    expect(m.total.kcal, closeTo(259, 0.001));
    // And it is on disk, not just in memory.
    expect((await store.load('2026-08-19')).total.kcal, closeTo(259, 0.001));
  });

  test('walking to yesterday loads that day, not a filtered cache', () async {
    await store.save(DiaryDay.empty('2026-08-18').addEntry(
        'Lunch', quickAddEntry(id: 'y', kcal: 500)));
    final m = model();
    await m.ensureLoaded();
    await m.logProduct(oats(), oats().servings.first,
        meal: 'Breakfast', quantity: 1);

    await m.shiftDay(-1);
    expect(m.date, '2026-08-18');
    expect(m.isToday, isFalse);
    expect(m.total.kcal, 500);

    await m.shiftDay(1);
    expect(m.date, '2026-08-19');
    expect(m.total.kcal, closeTo(129.5, 0.001));
  });

  test('a meal the user renamed still shows the day it was logged under',
      () async {
    await store.save(DiaryDay.empty('2026-08-19')
        .addEntry('Kvöldmat', quickAddEntry(id: 'k', kcal: 300)));
    final m = model();
    await m.ensureLoaded();
    expect(m.visibleMealNames, [...defaultMealNames, 'Kvöldmat']);
  });

  test('quantity edits and removal persist', () async {
    final m = model();
    await m.ensureLoaded();
    final entry = await m.logProduct(oats(), oats().servings.first,
        meal: 'Breakfast', quantity: 1);

    await m.setQuantity(entry, 3);
    expect((await store.load('2026-08-19')).total.kcal, closeTo(388.5, 0.001));

    await m.removeEntry(entry.id);
    expect(m.day.isEmpty, isTrue);
    expect(await store.loggedDates(), isEmpty);
  });

  test('re-logging a recent keeps its snapshot', () async {
    final m = model();
    await m.ensureLoaded();
    final first = await m.logProduct(oats(), oats().servings.first,
        meal: 'Breakfast', quantity: 1);
    final again = await m.logAgain(first, meal: 'Snacks');

    expect(again.id, isNot(first.id));
    expect(again.perServing.kcal, first.perServing.kcal);
    expect(m.day.meal('Snacks')!.entries.single.name, 'Havregryn');
  });

  test('copying a meal from another day brings its rows over', () async {
    await store.save(DiaryDay.empty('2026-08-18')
        .addEntry('Lunch', quickAddEntry(id: 'a', kcal: 400))
        .addEntry('Lunch', quickAddEntry(id: 'b', kcal: 100)));
    final m = model();
    await m.ensureLoaded();
    await m.copyMealFrom('2026-08-18', 'Lunch');

    expect(m.day.meal('Lunch')!.entries.length, 2);
    expect(m.total.kcal, 500);
    expect(m.day.meal('Lunch')!.entries.map((e) => e.id), isNot(contains('a')));
  });

  test('no goal set: the diary counts and says nothing about remaining', () {
    final m = model();
    expect(m.calorieGoal, isNull);
    expect(m.caloriesLeft, isNull);
    expect(m.goalSummary, 'No daily goal yet');
  });

  test('a null store keeps working in memory', () async {
    final m = DiaryModel(null, clock: () => now);
    await m.ensureLoaded();
    await m.logProduct(oats(), oats().servings.first,
        meal: 'Lunch', quantity: 1);
    expect(m.total.kcal, closeTo(129.5, 0.001));
  });

  test('a store that refuses the write leaves the screen as the user left it',
      () async {
    final m = model(s: _FailingStore());
    await m.ensureLoaded();
    await m.logProduct(oats(), oats().servings.first,
        meal: 'Lunch', quantity: 1);
    expect(m.day.entryCount, 1, reason: 'the row must not vanish mid-tap');
  });

  test('recents come from the days already logged', () async {
    await store.save(DiaryDay.empty('2026-08-18')
        .addEntry('Lunch', quickAddEntry(id: 'a', kcal: 400, name: 'Pizza')));
    final m = model();
    await m.ensureRecents();
    expect(m.recents.single.name, 'Pizza');
  });

  group('meals settings', () {
    Future<AppSettings> settings() =>
        AppSettings.load(File('${root.path}/settings.json'));

    test('setMeals saves names with hours; a dropped meal loses its hour',
        () async {
      final s = await settings();
      final m = DiaryModel(store, settings: s, clock: () => now);
      await m.setMeals(const ['Breakfast', 'Lunch', 'Dinner'],
          const {'Breakfast': '18:00', 'Snacks': '15:00'});
      expect(m.mealNames, ['Breakfast', 'Lunch', 'Dinner']);
      // Snacks is not a meal any more, so its hour must not linger on disk.
      expect(s.mealStarts, {'Breakfast': '18:00'});
    });

    test('currentMeal follows the clock around midnight', () async {
      final s = await settings();
      // Night shift: Breakfast 18:00, Lunch 23:00, Dinner 03:30. The test
      // clock says 09:00 — Dinner's window is still the open one.
      final m = DiaryModel(store, settings: s, clock: () => now);
      await m.setMeals(const ['Breakfast', 'Lunch', 'Dinner', 'Snacks'],
          const {'Breakfast': '18:00', 'Lunch': '23:00', 'Dinner': '03:30'});
      expect(m.currentMeal, 'Dinner');
    });

    test('no hours set means no current meal', () async {
      final m = model();
      expect(m.currentMeal, isNull);
    });
  });
}
