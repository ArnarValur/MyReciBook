// Post-save edit in the row editor (2026-08-20, replacing the old
// ImportReviewScreen.edit): the saved recipe opens in ManualEntryScreen
// pre-filled, and saves back over the same file. The envelope (id, source,
// extraction stamps, notes, favorite) must survive, no extraction call may
// fire, and — the fix this unification exists for — an edited line's
// qty/unit/item are re-parsed from the visible text while its pantry link
// survives. Same real-IO settle harness as app_flow_test.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';
import 'package:myrecibook/ui/grocery_model.dart';
import 'package:myrecibook/ui/widgets/editor_fields.dart';
import 'package:provider/provider.dart';

class NoCallExtractor implements Extractor {
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    calls++;
    throw StateError('edit mode must never extract');
  }
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late LocalPantryStore pantry;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_edit_test');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    pantry = LocalPantryStore(Directory('${tmp.path}/pantry'));
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  Widget app(Extractor extractor) => buildApp(
      store: store, extractor: extractor, pantry: pantry, picker: () async => []);

  Future<void> seed() => store.save(
        const Recipe(
          schemaVersion: 1,
          id: 'e1',
          title: 'Soup',
          source: RecipeSource(
              type: 'screenshot', importedAt: '2026-08-06T00:00:00.000Z'),
          servings: Servings(raw: '6 loaves'),
          times: RecipeTimes(raw: '25 min'),
          ingredients: [
            Ingredient(raw: '2 carrots', qty: 2, item: 'carrots', confidence: 0.95),
            Ingredient(raw: '1 cup broth', confidence: 0.9),
          ],
          steps: [RecipeStep(raw: 'Simmer.', confidence: 0.9)],
          notes: 'keep me',
          favorite: true,
          extraction: Extraction(
              model: 'orig-model',
              mode: 'image',
              extractedAt: '2026-08-06T00:00:00.000Z'),
        ),
        const [],
      );

  Future<void> openEditor(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await settle(tester);
    await tester.tap(find.byKey(const Key('edit-button')));
    await settle(tester);
  }

  Future<void> saveChanges(WidgetTester tester) async {
    await tester.scrollUntilVisible(find.text('Save changes'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await settle(tester);
  }

  testWidgets('edit: opens the row editor pre-filled, saves back in place — '
      'envelope preserved, edited line re-parsed', (tester) async {
    await tester.runAsync(seed);
    final extractor = NoCallExtractor();
    await tester.pumpWidget(app(extractor));
    await settle(tester);

    await openEditor(tester, 'Soup');

    // The row editor in edit dress — not the import review.
    expect(find.text('Edit recipe'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    // Pre-fill: title, structured metadata read out of the raw fields,
    // ingredient rows, steps.
    expect(find.widgetWithText(TextField, 'Soup'), findsOneWidget);
    expect(find.text('6 servings'), findsOneWidget); // "6 loaves" → 6
    expect(
        tester
            .widget<TextField>(find.byKey(const Key('duration-value')))
            .controller!
            .text,
        '25');
    expect(find.widgetWithText(TextField, '2 carrots'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1 cup broth'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Soup'), 'Root Soup');
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup broth'), '1 cup stock');
    await tester.pump();
    await saveChanges(tester);

    // Back on detail, updated in place.
    expect(find.text('Root Soup'), findsWidgets);

    // Same file, same id — no duplicate was written.
    final jsons = store.root
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.json'));
    expect(jsons, hasLength(1));

    final loaded = await tester.runAsync(() => store.load('e1'));
    expect(loaded!.title, 'Root Soup');
    // Untouched row: the stored parse rides through verbatim.
    expect(loaded.ingredients[0].raw, '2 carrots');
    expect(loaded.ingredients[0].qty, 2);
    expect(loaded.ingredients[0].item, 'carrots');
    expect(loaded.ingredients[0].confidence, 0.95);
    // Edited row: re-parsed from the visible text — no stale parse behind
    // new words (the bug the one-editor unification kills).
    expect(loaded.ingredients[1].raw, '1 cup stock');
    expect(loaded.ingredients[1].qty, 1);
    expect(loaded.ingredients[1].unit, 'cup');
    expect(loaded.ingredients[1].item, 'stock');
    expect(loaded.ingredients[1].confidence, 0.9); // origin field preserved
    // Untouched metadata: the original raw survives the save untouched —
    // the stepper showed "6 servings" but the user never stepped it.
    expect(loaded.servings?.raw, '6 loaves');
    expect(loaded.servings?.amount, isNull);
    expect(loaded.times?.raw, '25 min');
    // Envelope.
    expect(loaded.notes, 'keep me');
    expect(loaded.favorite, isTrue);
    expect(loaded.extraction?.model, 'orig-model'); // rule 2: never re-stamped
    expect(loaded.source.importedAt, '2026-08-06T00:00:00.000Z');
    expect(extractor.calls, 0);
  });

  testWidgets('touched stepper upgrades servings to structured on save',
      (tester) async {
    await tester.runAsync(seed);
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await openEditor(tester, 'Soup');
    await tester.tap(find.byKey(const Key('servings-plus'))); // 6 → 7
    await tester.pump();
    await saveChanges(tester);

    final loaded = await tester.runAsync(() => store.load('e1'));
    expect(loaded!.servings?.amount, 7);
    expect(loaded.servings?.raw, '7 servings');
    expect(loaded.times?.raw, '25 min'); // untouched neighbour keeps its raw
  });

  // The cake regression (Arnar 2026-08-30): a rescue arrived with Prep +
  // Refrigerate + Total, the editor's single-total pill collapsed them on
  // save, and no test crossed the import → save → edit → save seam to notice.
  Future<void> seedCake() => store.save(
        const Recipe(
          schemaVersion: 1,
          id: 'e2',
          title: 'Peach Tiramisu',
          source: RecipeSource(
              type: 'screenshot', importedAt: '2026-08-29T00:00:00.000Z'),
          times: RecipeTimes(
            prepMin: 30,
            totalMin: 270,
            raw: 'Prep Time: 30 mins, Refrigerate Time: 4 hrs, '
                'Total Time: 4 hrs 30 mins',
            extra: [ExtraTime(label: 'Refrigerate', min: 240)],
          ),
          ingredients: [Ingredient(raw: '4 peaches')],
          steps: [RecipeStep(raw: 'Layer.')],
        ),
        const [],
      );

  Finder timeValue(String label) => find.descendant(
      of: find.ancestor(
          of: find.text(label), matching: find.byType(DurationField)),
      matching: find.byKey(const Key('duration-value')));

  testWidgets('imported multi-part times survive an unrelated edit',
      (tester) async {
    await tester.runAsync(seedCake);
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await openEditor(tester, 'Peach Tiramisu');
    // One pill per part, in the natural unit — the 270-min total reads 4,5 hr.
    expect(tester.widget<TextField>(timeValue('Prep')).controller!.text, '30');
    expect(tester.widget<TextField>(timeValue('Refrigerate')).controller!.text,
        '4');
    expect(
        tester.widget<TextField>(timeValue('Total')).controller!.text, '4,5');

    await tester.enterText(
        find.widgetWithText(TextField, 'Peach Tiramisu'), 'Mum\'s Tiramisu');
    await saveChanges(tester);

    final loaded = await tester.runAsync(() => store.load('e2'));
    expect(loaded!.title, 'Mum\'s Tiramisu');
    // Untouched times ride through whole — parts AND the verbatim raw.
    expect(loaded.times?.prepMin, 30);
    expect(loaded.times?.totalMin, 270);
    expect(loaded.times?.extra.single.label, 'Refrigerate');
    expect(loaded.times?.extra.single.min, 240);
    expect(loaded.times?.raw,
        'Prep Time: 30 mins, Refrigerate Time: 4 hrs, Total Time: 4 hrs 30 mins');
  });

  testWidgets('time pills: edit one, add one, remove one — the file follows',
      (tester) async {
    await tester.runAsync(seedCake);
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await openEditor(tester, 'Peach Tiramisu');

    // Edit Prep 30 → 45.
    await tester.enterText(timeValue('Prep'), '45');
    await tester.pump();

    // Add a Cook time of 20 min through the add-time sheet.
    await tester.tap(find.byKey(const Key('add-time')));
    await settle(tester, rounds: 4);
    await tester.tap(find.byKey(const Key('add-time-Cook')));
    await settle(tester, rounds: 4);
    await tester.enterText(timeValue('Cook'), '20');
    await tester.pump();

    // Remove Refrigerate with its pill's ✕.
    await tester.tap(find.descendant(
        of: find.ancestor(
            of: find.text('Refrigerate'), matching: find.byType(DurationField)),
        matching: find.byKey(const Key('duration-remove'))));
    await tester.pump();

    await saveChanges(tester);

    final loaded = await tester.runAsync(() => store.load('e2'));
    expect(loaded!.times?.prepMin, 45);
    expect(loaded.times?.cookMin, 20);
    expect(loaded.times?.totalMin, 270);
    expect(loaded.times?.extra, isEmpty);
    // Raw is rebuilt from the parts, so it never lies about them.
    expect(loaded.times?.raw, 'Prep 45 min, Cook 20 min, Total 4 hr 30 min');
  });

  testWidgets('edit re-keys the grocery list when a line changes',
      (tester) async {
    await tester.runAsync(seed);
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await tester.tap(find.text('Soup'));
    await settle(tester);
    await tester.tap(find.text('Grocery'));
    await settle(tester, rounds: 6);

    await tester.tap(find.byKey(const Key('edit-button')));
    await settle(tester);
    // The line had no stored item, so its grocery key was the raw text.
    // The edit re-parses it ("stock" becomes the item), and the detail
    // screen's syncRecipe wiring re-keys the list row.
    await tester.enterText(
        find.widgetWithText(TextField, '1 cup broth'), '1 cup stock');
    await tester.pump();
    await saveChanges(tester);

    final grocery = Provider.of<GroceryModel>(
        tester.element(find.byType(MaterialApp)),
        listen: false);
    final keys = [for (final i in grocery.items) i.key];
    expect(keys, contains('stock')); // parsed item, not the raw line
    expect(keys, isNot(contains('1 cup broth')));
    expect(keys, contains('carrots'));
  });

  testWidgets('linked line: shows the product name in the editor, reword '
      'keeps the link and the parse follows the text; link provenance pane '
      'shows for link imports', (tester) async {
    await tester.runAsync(() async {
      await pantry.save(const Product(
        schemaVersion: 1,
        barcode: '7038010000001',
        name: 'Mellommelk 2,0% fett',
        quantity: '1 l',
        source: 'off',
      ));
      await store.save(
        const Recipe(
          schemaVersion: 1,
          id: 'e2',
          title: 'Porridge',
          source: RecipeSource(
              type: 'link',
              importedAt: '2026-08-20T00:00:00.000Z',
              url: 'https://example.com/porridge'),
          ingredients: [
            Ingredient(
                raw: '2 dl milk',
                qty: 2,
                unit: 'dl',
                item: 'milk',
                productRef: '7038010000001'),
          ],
          steps: [RecipeStep(raw: 'Simmer.')],
        ),
        const [],
      );
    });
    await tester.pumpWidget(app(NoCallExtractor()));
    await settle(tester);

    await openEditor(tester, 'Porridge');

    // Link import: the provenance pane names the page instead of screenshots.
    expect(find.byKey(const Key('edit-originals-pane')), findsOneWidget);
    expect(find.text('From a link'), findsOneWidget);
    expect(find.text('example.com'), findsOneWidget);

    // The linked row wears the product's name (display-time substitution).
    expect(
        find.textContaining('2 dl Mellommelk 2,0% fett', findRichText: true),
        findsOneWidget);
    expect(find.text('2 dl milk'), findsNothing);

    // Tap → the stored text comes back; reword it.
    await tester.tap(find.byKey(const Key('linked-line-0')));
    await settle(tester, rounds: 3);
    expect(find.text('2 dl milk'), findsOneWidget);
    await tester.enterText(
        find.byKey(const Key('manual-ing-0')), '3 dl whole milk');
    await tester.pump();
    await saveChanges(tester);

    final loaded = await tester.runAsync(() => store.load('e2'));
    // The parse refreshed with the text…
    expect(loaded!.ingredients[0].raw, '3 dl whole milk');
    expect(loaded.ingredients[0].qty, 3);
    expect(loaded.ingredients[0].unit, 'dl');
    expect(loaded.ingredients[0].item, 'whole milk');
    // …and the link survived the rewording.
    expect(loaded.ingredients[0].productRef, '7038010000001');
    expect(loaded.source.url, 'https://example.com/porridge');
  });
}
