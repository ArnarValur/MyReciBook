// The Pantry tab's shelf behaviour (design 1b): the fold nobody chose, the
// fold the user chose, and search flattening the whole thing. The starter
// packs are the reason this exists — 3×~60 rows must not be on screen, or
// built, just because the app shipped with them.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/ui/pantry/manual_product_screen.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';
import 'package:myrecibook/ui/pantry/pantry_tab.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

void main() {
  Product product(String name,
          {required String category, String source = 'off', String? brand}) =>
      Product(
        schemaVersion: Product.currentSchemaVersion,
        barcode: source == 'off' ? '70000000${name.length}$category' : '',
        name: name,
        brand: brand,
        source: source,
        tags: [category],
      );

  /// A shelf with two scanned dairy products and three built-in vegetables.
  /// ensureLoaded FIRST: the tab's own post-frame load would otherwise rescan
  /// the null store and hand us an empty pantry.
  Future<PantryModel> shelf() async {
    final model = PantryModel(null);
    await model.ensureLoaded();
    await model.upsert(product('Lettmelk', category: 'Dairy', brand: 'TINE'));
    await model.upsert(product('Kefir', category: 'Dairy', brand: 'Biola'));
    for (final v in ['Broccoli', 'Carrot', 'Kale']) {
      await model.upsert(product(v, category: 'Veggies', source: 'starter'));
    }
    return model;
  }

  Future<void> pump(WidgetTester tester, PantryModel model) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: model),
        // No settings file in a widget test: the fold works, it just does
        // not survive a restart.
        Provider<AppSettings?>.value(value: null),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('starter packs arrive folded, the user\'s own shelf open',
      (tester) async {
    await pump(tester, await shelf());

    // Every category is on screen with its count, no horizontal scrolling.
    expect(find.text('🥛 Dairy'), findsOneWidget);
    expect(find.text('🥦 Veggies'), findsOneWidget);
    expect(find.text('5 products'), findsOneWidget);

    // Scanned products are visible; the built-in vegetables are not.
    expect(find.text('Lettmelk'), findsOneWidget);
    expect(find.text('Broccoli'), findsNothing);
  });

  testWidgets('tapping a folded header opens it, tapping again folds it back',
      (tester) async {
    await pump(tester, await shelf());

    await tester.tap(find.text('🥦 Veggies'));
    await tester.pumpAndSettle();
    expect(find.text('Broccoli'), findsOneWidget);

    await tester.tap(find.text('🥦 Veggies'));
    await tester.pumpAndSettle();
    expect(find.text('Broccoli'), findsNothing);
  });

  testWidgets('search flattens the shelf — including folded sections',
      (tester) async {
    await pump(tester, await shelf());

    await tester.enterText(find.byKey(const Key('pantry-search')), 'broc');
    await tester.pumpAndSettle();

    expect(find.text('Broccoli'), findsOneWidget); // folded, but findable
    expect(find.text('🥦 Veggies'), findsNothing); // headers step aside
    expect(find.text('Lettmelk'), findsNothing);

    // Brand matches too, and clearing puts the shelf back.
    await tester.enterText(find.byKey(const Key('pantry-search')), 'biola');
    await tester.pumpAndSettle();
    expect(find.text('Kefir'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('pantry-search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nothing on the shelf matches that.'), findsOneWidget);
  });

  // Every settings.json touch goes through tester.runAsync: real file I/O
  // never completes inside the widget tester's fake-async zone, and a plain
  // await here hangs the whole file instead of failing.
  testWidgets('the fold is written down, and a stored fold wins on the way in',
      (tester) async {
    final tmp = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('recibook_shelf_test')))!;
    addTearDown(() => tmp.delete(recursive: true));
    final file = File('${tmp.path}/settings.json');
    final settings = (await tester.runAsync(() => AppSettings.load(file)))!;

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: await shelf()),
        Provider<AppSettings?>.value(value: settings),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    await tester.pumpAndSettle();

    // Nothing is stored until the user actually chooses something.
    expect(settings.pantryOpenSections, isNull);

    // The tap itself runs on the real clock: the tab's write is dart:io, and
    // in the fake zone its continuations would never run.
    await tester.runAsync(() async {
      await tester.tap(find.text('🥦 Veggies'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    final stored = (await tester.runAsync(() => AppSettings.load(file)))!;
    expect(stored.pantryOpenSections, containsAll(['Dairy', 'Veggies']));

    // A fresh tab over the same file opens exactly what was left open — the
    // starter pack included, because the user asked for it last time.
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: await shelf()),
        Provider<AppSettings?>.value(value: stored),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Broccoli'), findsOneWidget);
  });

  testWidgets('an empty pantry: no search box, the zero state instead',
      (tester) async {
    final model = PantryModel(null);
    await model.ensureLoaded();
    await pump(tester, model);

    expect(find.byKey(const Key('pantry-search')), findsNothing);
    expect(find.text('0 products'), findsOneWidget);
    expect(find.byKey(const Key('pantry-starter-foods')), findsOneWidget);
  });

  testWidgets('before the first scan lands: a spinner, never "0 products"',
      (tester) async {
    final store = _GateStore();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: PantryModel(store)),
        Provider<AppSettings?>.value(value: null),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    // One plain pump, no settle: the spinner animates for as long as the
    // scan runs, and the scan is waiting on the gate.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('0 products'), findsNothing);
    expect(find.byIcon(Icons.kitchen_rounded), findsNothing); // no flash

    store.open();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('0 products'), findsOneWidget);
    expect(find.byIcon(Icons.kitchen_rounded), findsOneWidget);
  });

  testWidgets('a failed first scan offers a retry, never an eternal spinner',
      (tester) async {
    final store = _FlakyStore();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: PantryModel(store)),
        Provider<AppSettings?>.value(value: null),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
    expect(find.text('0 products'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(store.listCalls, 2);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('0 products'), findsOneWidget);
  });

  testWidgets('the quarter-width add opens the create screen, no barcode',
      (tester) async {
    final store = _GateStore();
    final model = PantryModel(store);
    store.open();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<PantryModel>.value(value: model),
        Provider<AppSettings?>.value(value: null),
      ],
      child: MaterialApp(theme: rbLightTheme(), home: const PantryTab()),
    ));
    await model.ensureLoaded();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pantry-new-product')));
    await tester.pumpAndSettle();
    final screen = tester
        .widget<ManualProductScreen>(find.byType(ManualProductScreen));
    expect(screen.barcode, isNull);
    expect(screen.initial, isNull);
  });

  test('two ensureLoaded calls in flight share one store scan', () async {
    final store = _GateStore();
    final model = PantryModel(store);

    final first = model.ensureLoaded();
    final second = model.ensureLoaded();
    expect(model.loading, isTrue);
    expect(model.busy, isFalse); // a load must never hold the Scan button

    store.open();
    await Future.wait([first, second]);
    expect(store.listCalls, 1);
    expect(model.loading, isFalse);
    expect(model.loaded, isTrue);

    await model.ensureLoaded(); // loaded: still no second scan
    expect(store.listCalls, 1);
  });
}

/// Store whose first scan throws — pins the retry door on the load gate.
class _FlakyStore implements ProductStore {
  int listCalls = 0;

  @override
  Future<PantryResult> listAll() async {
    listCalls++;
    if (listCalls == 1) throw Exception('transient read failure');
    return const PantryResult([], 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Store whose scan finishes only when the test opens the gate — pins the
/// in-flight window every ensureLoaded caller must share.
class _GateStore implements ProductStore {
  int listCalls = 0;
  final _gate = Completer<PantryResult>();

  void open() => _gate.complete(const PantryResult([], 0));

  @override
  Future<PantryResult> listAll() {
    listCalls++;
    return _gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
