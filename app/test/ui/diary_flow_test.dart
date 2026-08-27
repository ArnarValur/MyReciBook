// The diary screen end to end: open the day, add a food from the pantry,
// choose a serving, watch it land in the meal and move the day total.
//
// The stores here are in-memory. Real file IO inside testWidgets never
// completes — the fake clock owns the zone — so the on-disk contract is
// proven in diary_store_test.dart and diary_model_test.dart, which are plain
// tests against real temp dirs. This file proves the SCREEN.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/ui/diary/diary_model.dart';
import 'package:myrecibook/ui/diary/diary_tab.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

Product oats() => Product(
      schemaVersion: 1,
      barcode: '7311070003417',
      name: 'Havregryn',
      brand: 'Axa',
      source: 'off',
      addedAt: '2026-08-18T10:00:00.000Z',
      nutriments: Nutriments(kcal: 370, fat: 7, carbs: 59, protein: 13),
      servings: const [Serving(label: '1 dl', grams: 35)],
      defaultServing: 0,
    );

/// The pantry kept in a map — the model only needs listAll and save here.
class _MemoryPantryStore implements ProductStore {
  final products = <String, Product>{};

  @override
  Future<PantryResult> listAll() async =>
      PantryResult(products.values.toList(), 0);

  @override
  Future<Product?> load(String id) async => products[id];

  @override
  Future<Product> save(Product product) async =>
      products[product.id] = product;

  @override
  Future<Product> update(Product product) => save(product);

  @override
  Future<void> delete(String id) async => products.remove(id);

  @override
  Future<Product> attachImage(Product product, File photo) async => product;

  @override
  Future<Product> removeImage(Product product) async => product;

  @override
  File? imageFile(Product product) => null;
}

/// The day file kept in a map — same contract as LocalDiaryStore, no disk.
class _MemoryDiaryStore implements DiaryStore {
  final days = <String, DiaryDay>{};

  @override
  Future<DiaryDay> load(String date) async =>
      days[date] ?? DiaryDay.empty(date);

  @override
  Future<DiaryDay> save(DiaryDay day) async {
    if (day.isEmpty) {
      days.remove(day.date);
    } else {
      days[day.date] = day;
    }
    return day;
  }

  @override
  Future<List<String>> loggedDates() async =>
      days.keys.toList()..sort((a, b) => b.compareTo(a));

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) =>
      collectRecentEntries(this, days: days, limit: limit);
}

void main() {
  late _MemoryDiaryStore diaryStore;
  late _MemoryPantryStore pantryStore;
  late DiaryModel diary;
  final now = DateTime(2026, 8, 19, 9);

  setUp(() async {
    diaryStore = _MemoryDiaryStore();
    pantryStore = _MemoryPantryStore();
    await pantryStore.save(oats());
    diary = DiaryModel(diaryStore, clock: () => now);
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<DiaryModel>.value(value: diary),
        ChangeNotifierProvider<PantryModel>(
            create: (_) => PantryModel(pantryStore)),
      ],
      child: MaterialApp(
        theme: rbLightTheme(),
        home: const DiaryTab(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the day opens on today with MFP\'s four meals', (tester) async {
    await pump(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('19 Aug 2026'), findsOneWidget);
    for (final meal in ['BREAKFAST', 'LUNCH', 'DINNER', 'SNACKS']) {
      expect(find.text(meal), findsOneWidget);
    }
    // No goal set yet: the card says so instead of inventing 2000.
    expect(find.textContaining('No daily goal set yet'), findsOneWidget);
  });

  testWidgets('pantry food → serving → logged into the meal', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Add food').first);
    await tester.pumpAndSettle();
    expect(find.text('Add to breakfast'), findsOneWidget);

    // The shelf opens folded — nothing under a header is built until it is
    // tapped. Havregryn carries no category, so it sits under Other.
    expect(find.text('Havregryn'), findsNothing);
    await tester.tap(find.text('🏷️ Other'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Havregryn'));
    await tester.pumpAndSettle();

    // The pack's own portion is preselected, and 100 g is still offered.
    expect(find.text('1 dl'), findsWidgets);
    expect(find.text('100 g'), findsOneWidget);
    // One serving of 35 g at 370 kcal/100 g = 130 kcal.
    expect(find.text('130'), findsOneWidget);

    // .last: the add-food sheet's search field is still mounted underneath.
    await tester.enterText(find.byType(TextField).last, '2');
    await tester.pumpAndSettle();
    expect(find.text('259'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Add to Breakfast'));
    await tester.pumpAndSettle();
    // Two routes unwind: the log sheet pops, then the picker behind it.
    await tester.pumpAndSettle();

    // Back on the day: both sheets are gone, the row is there.
    expect(find.text('Add to breakfast'), findsNothing);
    expect(find.text('Havregryn'), findsOneWidget);
    expect(find.text('Axa · 2 × 1 dl'), findsOneWidget);
    expect(find.text('259'), findsWidgets);

    // And it is in the day the store holds, not just screen state.
    final saved = await diaryStore.load('2026-08-19');
    expect(saved.meal('Breakfast')!.entries.single.quantity, 2);
    expect(saved.total.kcal, closeTo(259, 0.5));
  });

  testWidgets('a logged row can be re-measured and removed', (tester) async {
    await diary.ensureLoaded();
    await diary.logProduct(oats(), oats().servings.first,
        meal: 'Lunch', quantity: 1);
    await pump(tester);

    await tester.tap(find.text('Havregryn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change amount'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('518'), findsWidgets);

    await tester.tap(find.text('Havregryn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from the diary'));
    await tester.pumpAndSettle();
    expect(find.text('Havregryn'), findsNothing);
    expect(await diaryStore.loggedDates(), isEmpty);
  });

  testWidgets('quick add logs calories with no food behind them',
      (tester) async {
    await pump(tester);
    await tester.tap(find.text('Add food').at(1)); // Lunch
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quick add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '600');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Quick add'), findsOneWidget);
    expect(find.text('600'), findsWidgets);
  });

  testWidgets('the day walker moves back and forward', (tester) async {
    await pump(tester);
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('18 Aug 2026'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });
}
