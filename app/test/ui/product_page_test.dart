// The unified product page (design 1c) — "the file IS the form". Four
// contracts this screen invents and nothing else covers:
//
//   1. Back saves. There is no Save button to press, so if the pop doesn't
//      flush, the edit is simply gone.
//   2. A blank nutrition field stays absent. The pantry's oldest rule is
//      "blank means not measured, never zero", and this page is now the
//      place zeros would get typed in.
//   3. A value nobody touched comes back byte-identical — the vitamins card
//      reads in mg, and a naive re-parse would rewrite the file with
//      floating-point noise on every save.
//   4. Renaming a barcode-less food MOVES its file. The stem is the name
//      slug, so a rename is a new file; without the move the shelf keeps
//      both copies.
//
// The store is in-memory (add_food_sheet_test's stance): this file proves
// the SCREEN, the on-disk contracts live in the store tests.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';
import 'package:myrecibook/ui/pantry/product_page.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

class _MemoryPantryStore implements ProductStore {
  final products = <String, Product>{};

  @override
  Future<PantryResult> listAll() async =>
      PantryResult(products.values.toList(), 0);

  @override
  Future<Product?> load(String id) async => products[id];

  @override
  Future<Product> save(Product product) async => products[product.id] = product;

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

/// A scanned milk, as the shelf holds it: macros, one vitamin stored in
/// grams (0.118 g of calcium reads as 118 mg), a pack size and a tag.
Product milk() => const Product(
      schemaVersion: 1,
      barcode: '7038010009457',
      name: 'Lettmelk',
      brand: 'Tine',
      quantity: '1 L',
      source: 'off',
      addedAt: '2026-08-17T10:00:00.000Z',
      nutriments: Nutriments.fromMap({'kcal': 37, 'fat': 0.5, 'calcium': 0.118}),
      tags: ['Dairy'],
    );

/// A hand-typed food: no barcode, so its filename is its name slug.
Product carrot() => const Product(
      schemaVersion: 1,
      barcode: '',
      name: 'Carrot',
      source: 'manual',
      addedAt: '2026-08-17T10:00:00.000Z',
      nutriments: Nutriments.fromMap({'kcal': 41}),
    );

Future<PantryModel> seeded(List<Product> products) async {
  final store = _MemoryPantryStore();
  for (final p in products) {
    store.products[p.id] = p;
  }
  final model = PantryModel(store);
  await model.rescan();
  return model;
}

/// The page under a route that can actually be popped, so "back saves" is
/// exercised through the real pop and not a method call.
Future<void> pumpPage(WidgetTester tester, PantryModel model, String id) async {
  // Tall viewport: the page is one long ListView and off-screen rows are
  // never built, so a short surface would prove nothing about the cards.
  tester.view.physicalSize = const Size(1200, 3400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ChangeNotifierProvider<PantryModel>.value(
    value: model,
    child: MaterialApp(
      theme: rbLightTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                    builder: (_) => ProductPage(productId: id))),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// Every editable value carries a key — the fields have no labels to find
/// them by, which is the point of the design.
Finder field(String key) => find.byKey(Key(key));

String valueOf(WidgetTester tester, String key) =>
    tester.widget<TextField>(field(key)).controller!.text;

/// The system back gesture / the app's own back button — both land on the
/// page's PopScope, which is what flushes.
Future<void> goBack(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the page opens as a form — no Save button, no edit door',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    expect(find.text('Edit this product'), findsNothing);
    expect(find.text('Save changes'), findsNothing);
    // Every value is a live field, drawn from the file.
    expect(valueOf(tester, 'product-name'), 'Lettmelk');
    expect(valueOf(tester, 'product-brand'), 'Tine');
    expect(valueOf(tester, 'product-size'), '1 L');
    expect(find.text('saved'), findsOneWidget);
  });

  testWidgets('back saves the typed name — nothing to press, nothing to lose',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    await tester.enterText(field('product-name'), 'Lettmelk 1%');
    await tester.pump();
    expect(find.text('saving…'), findsOneWidget);

    await goBack(tester);
    expect(model.byId(milk().id)!.name, 'Lettmelk 1%');
    // A hand-typed correction shields the file from the bulk refresh.
    expect(model.byId(milk().id)!.userEdited, isTrue);
  });

  testWidgets('merely opening a product never marks the file hand-edited',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);
    await goBack(tester);

    expect(model.byId(milk().id)!.userEdited, isFalse);
  });

  testWidgets('a blank nutrition field stays absent — never a zero',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    // Fat was 0.5; emptying it means "not measured", not "contains none".
    await tester.enterText(field('nutrient-fat'), '');
    await goBack(tester);

    final values = model.byId(milk().id)!.nutriments!.values;
    expect(values.containsKey('fat'), isFalse);
    expect(values['kcal'], 37);
  });

  testWidgets('the vitamins card reads in mg and writes back grams',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    // 0.118 g of calcium is unreadable as written, so the row says 118 mg.
    expect(valueOf(tester, 'nutrient-calcium'), '118');
    expect(find.text('mg'), findsWidgets);
    await tester.enterText(field('nutrient-calcium'), '236');
    await goBack(tester);

    expect(model.byId(milk().id)!.nutriments!['calcium'], closeTo(0.236, 1e-9));
  });

  testWidgets('a value nobody touched comes back exactly as it went in',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    await tester.enterText(field('product-brand'), 'Q-Meieriene');
    await goBack(tester);

    // Not 0.11800000000000001: an untouched field is carried, not re-parsed.
    expect(model.byId(milk().id)!.nutriments!['calcium'], 0.118);
    expect(model.byId(milk().id)!.brand, 'Q-Meieriene');
  });

  testWidgets('SIZE edits the pack size, and emptying it removes the field',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    await tester.enterText(field('product-size'), '400 ml');
    await goBack(tester);
    expect(model.byId(milk().id)!.quantity, '400 ml');

    await pumpPage(tester, model, milk().id);
    await tester.enterText(field('product-size'), '');
    await goBack(tester);
    // Absent, not "" — the file is what the user sees.
    expect(model.byId(milk().id)!.quantity, isNull);
    expect(model.byId(milk().id)!.toJson()['quantity'], isNull);
  });

  testWidgets('renaming a barcode-less food moves its file, never copies it',
      (tester) async {
    final model = await seeded([carrot()]);
    await pumpPage(tester, model, carrot().id);

    await tester.enterText(field('product-name'), 'Gulrot');
    // Mid-typing writes are held back: a half-typed name must not spawn a
    // file per keystroke.
    await tester.pump(const Duration(seconds: 2));
    expect(model.products.length, 1);
    expect(model.byId('carrot')!.name, 'Carrot');

    await goBack(tester);
    expect(model.products.length, 1);
    expect(model.byId('carrot'), isNull);
    expect(model.byId('gulrot')!.name, 'Gulrot');
  });

  testWidgets('a name typed to nothing falls back to the stored one',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    await tester.enterText(field('product-name'), '');
    await goBack(tester);

    expect(model.byId(milk().id)!.name, 'Lettmelk');
  });

  testWidgets('the portion row edits in place and the update door is explicit',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    expect(find.text('Update from Open Food Facts'), findsOneWidget);
    await tester.enterText(field('portion-label'), '1 glass');
    await tester.enterText(field('portion-grams'), '200');
    await goBack(tester);

    final saved = model.byId(milk().id)!;
    expect(saved.servings.single.label, '1 glass');
    expect(saved.servings.single.grams, 200);
  });

  testWidgets('the chips are the tags, and "+ Add tag" opens the full cloud',
      (tester) async {
    final model = await seeded([milk()]);
    await pumpPage(tester, model, milk().id);

    expect(find.text('🥛 Dairy'), findsOneWidget);
    await tester.tap(find.byKey(const Key('product-add-tag')));
    await tester.pumpAndSettle();

    // The create screen's own cloud, sheet-side: every canonical category
    // plus the door to invent one.
    expect(find.text('Add your own'), findsOneWidget);
    await tester.tap(find.text('🍷 Wine & beer'));
    await tester.pumpAndSettle();
    expect(model.byId(milk().id)!.tags, ['Dairy', 'Wine & beer']);
    // Shelving is not a data correction: it must not shield the file from
    // the bulk refresh (Arnar, 2026-08-19).
    expect(model.byId(milk().id)!.userEdited, isFalse);
  });

  testWidgets('a barcode-less food is offered no Open Food Facts door',
      (tester) async {
    final model = await seeded([carrot()]);
    await pumpPage(tester, model, carrot().id);

    expect(find.text('Update from Open Food Facts'), findsNothing);
    expect(find.textContaining('Your own entry'), findsOneWidget);
  });
}
