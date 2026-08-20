// The row editor's create mode ("New Recipe", the 5b promise): sheet door →
// row editor → saved file shape. The file must be source.type "manual", no
// extraction, no images — and round-trip through the store scan back into
// the cookbook grid. Structured metadata (stepper/duration/cover), inline
// parse corrections, and pantry-linked rows are covered here too.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/main.dart';

/// Never called — manual entry must not touch the extractor.
class ExplodingExtractor implements Extractor {
  int calls = 0;

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    calls++;
    throw StateError('manual entry must never extract');
  }
}

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late LocalPantryStore pantry;
  late ExplodingExtractor extractor;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_manual');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    pantry = LocalPantryStore(Directory('${tmp.path}/pantry'));
    extractor = ExplodingExtractor();
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  Widget app({List<File> Function()? gallery}) => buildApp(
      store: store,
      extractor: extractor,
      pantry: pantry,
      picker: () async => gallery == null ? const [] : gallery());

  Future<void> settle(WidgetTester tester, {int rounds = 32}) async {
    for (var i = 0; i < rounds; i++) {
      await tester
          .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  List<File> savedJsonFiles() => !store.root.existsSync()
      ? const []
      : store.root
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

  Future<void> openManual(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 6);
    await tester.tap(find.byKey(const Key('import-manual-tile')));
    await settle(tester, rounds: 6);
  }

  testWidgets('sheet shows the New Recipe door with the 5b promise copy',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await settle(tester, rounds: 6);

    expect(find.text('New Recipe'), findsOneWidget);
    expect(find.text('no AI, no cap — always unlimited'), findsOneWidget);
  });

  testWidgets('typed recipe saves as source.type manual with structured '
      'servings/times, no extraction, no images, and lands in the cookbook',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await openManual(tester);
    expect(find.text('New Recipe'), findsOneWidget);

    await tester.enterText(
        find.byKey(const Key('manual-title')), "Nan's bread");
    // Stepper starts at 4 — two taps up says "6 servings", and exactly that
    // label is what the file's raw stores.
    await tester.tap(find.byKey(const Key('servings-plus')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('servings-plus')));
    await tester.pump();
    expect(find.text('6 servings'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('duration-value')), '25');
    await tester.pump();

    // Row editor (2026-08-19): one field per ingredient, Enter grows the
    // list; enterText + a manual add stand in for the Enter key here.
    await tester.enterText(
        find.byKey(const Key('manual-ing-0')), '2 cups flour');
    await tester.pump();
    await tester.tap(find.text('Add ingredient'));
    await tester.pump();
    await tester.enterText(
        find.byKey(const Key('manual-ing-1')), ' 1 tsp salt ');
    await tester.pump();

    // Each typed row structures itself: parse chips + an unlinked 'Link'
    // chip (empty pantry in this seam... the products exist but nothing is
    // linked, so both rows still say Link).
    expect(find.text('cup'), findsOneWidget);
    expect(find.text('flour'), findsOneWidget);
    expect(find.text('tsp'), findsOneWidget);
    expect(find.text('salt'), findsOneWidget);
    expect(find.text('Link'), findsNWidgets(2));

    // ListView materializes lazily — scroll the step row into existence
    // before targeting it (ensureVisible needs a live element).
    await tester.scrollUntilVisible(find.byKey(const Key('manual-step-0')), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.enterText(find.byKey(const Key('manual-step-0')), 'Mix.');
    await tester.pump();
    await tester.tap(find.text('Add step'));
    await tester.pump();
    // Steps number themselves as rows are added.
    expect(find.text('1.'), findsOneWidget);
    expect(find.text('2.'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('manual-step-1')), 'Bake.');
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Save to cookbook'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    // Back on the cookbook with the new recipe in the grid (round-trip
    // through listAll proves fromJson tolerates type "manual").
    expect(find.text("Nan's bread"), findsOneWidget);

    final files = savedJsonFiles();
    expect(files, hasLength(1));
    final json =
        jsonDecode(files.single.readAsStringSync()) as Map<String, dynamic>;
    expect((json['source'] as Map)['type'], 'manual');
    expect((json['source'] as Map)['original_images'], isNull);
    expect(json['extraction'], isNull);
    expect(json['title'], "Nan's bread");
    // Structured from the first save (editor_fields): amount feeds the
    // nutrition math, raw is exactly the label the stepper displayed.
    expect((json['servings'] as Map)['amount'], 6);
    expect((json['servings'] as Map)['raw'], '6 servings');
    expect((json['times'] as Map)['total_min'], 25);
    expect((json['times'] as Map)['raw'], '25 min');
    expect([for (final i in json['ingredients'] as List) i['raw']],
        ['2 cups flour', '1 tsp salt']); // rows trimmed, empty rows dropped
    // Born parsed (2026-08-19): the deterministic parse is stored at save,
    // so the file is calorie-computable from its first write.
    expect([for (final i in json['ingredients'] as List) i['qty']], [2, 1]);
    expect([for (final i in json['ingredients'] as List) i['unit']],
        ['cup', 'tsp']);
    expect([for (final i in json['ingredients'] as List) i['item']],
        ['flour', 'salt']);
    expect([for (final i in json['ingredients'] as List) i['product_ref']],
        [null, null]); // nothing linked — the key stays absent, never a lie
    expect([for (final s in json['steps'] as List) s['raw']], ['Mix.', 'Bake.']);
    expect(extractor.calls, 0); // no AI involved, ever

    // Round-trip pin: the saved file parses back identically.
    final back = Recipe.fromJson(json);
    expect(back.source.type, 'manual');
    expect(back.extraction, isNull);
    expect(jsonEncode(back.toJson()), jsonEncode(json));
  });

  testWidgets('empty title blocks the save with the validator copy',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await openManual(tester);
    await tester.enterText(find.byKey(const Key('manual-ing-0')), '2 eggs');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Save to cookbook'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Save to cookbook'));
    // Short settle keeps the 4s snackbar alive for the assertion.
    await settle(tester, rounds: 6);

    expect(find.text('empty title'), findsOneWidget);
    expect(savedJsonFiles(), isEmpty);
    expect(find.text('New Recipe'), findsOneWidget); // did not pop
  });

  testWidgets('inline chips: qty edits in place, the unit chip opens the '
      'inline option row — no dialog — and the correction is what saves',
      (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);

    await openManual(tester);
    await tester.enterText(find.byKey(const Key('manual-title')), 'Chips');
    await tester.enterText(
        find.byKey(const Key('manual-ing-0')), '2 dl melk');
    await tester.pump();

    // Qty chip → tiny in-place field. Commit via the keyboard's done.
    await tester.tap(find.byKey(const Key('ing-qty-0')));
    await tester.pump();
    expect(find.byKey(const Key('qty-edit-0')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing); // the popup is dead
    await tester.enterText(find.byKey(const Key('qty-edit-0')), '3');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.byKey(const Key('qty-edit-0')), findsNothing);
    expect(
        find.descendant(
            of: find.byKey(const Key('ing-qty-0')),
            matching: find.text('3')),
        findsOneWidget);

    // Unit chip → inline option row (unlinked: the full common set).
    await tester.tap(find.byKey(const Key('ing-unit-0')));
    await tester.pump();
    for (final u in ['g', 'kg', 'ml', 'dl', 'l', 'tsp', 'tbsp', 'cup']) {
      expect(find.byKey(Key('unit-option-$u')), findsOneWidget);
    }
    expect(find.byKey(const Key('unit-option-none')), findsOneWidget);
    await tester.tap(find.byKey(const Key('unit-option-l')));
    await tester.pump();
    expect(find.byKey(const Key('unit-option-l')), findsNothing); // closed
    expect(
        find.descendant(
            of: find.byKey(const Key('ing-unit-0')),
            matching: find.text('l')),
        findsOneWidget);

    await tester.scrollUntilVisible(find.text('Save to cookbook'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    final json = jsonDecode(savedJsonFiles().single.readAsStringSync())
        as Map<String, dynamic>;
    final ing = (json['ingredients'] as List).single as Map;
    expect(ing['raw'], '2 dl melk'); // the typed line is never rewritten
    expect(ing['qty'], 3); // the correction rides beside it
    expect(ing['unit'], 'l');
    expect(ing['item'], 'melk');
  });

  testWidgets('cover picked in the editor is copied into the folder as the '
      'saved recipe\'s cover', (tester) async {
    final photo = File('${tmp.path}/pick.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 4, height: 4)));
    await tester.pumpWidget(app(gallery: () => [photo]));
    await settle(tester);

    await openManual(tester);
    expect(find.text('Add a cover photo'), findsOneWidget);
    await tester.tap(find.byKey(const Key('cover-field')));
    await settle(tester, rounds: 6);
    await tester.tap(find.byKey(const Key('cover-field-gallery')));
    await settle(tester, rounds: 6);
    expect(find.text('Add a cover photo'), findsNothing); // slot filled

    await tester.enterText(find.byKey(const Key('manual-title')), 'Kake');
    await tester.enterText(find.byKey(const Key('manual-ing-0')), '2 egg');
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Save to cookbook'), 120,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('Save to cookbook'));
    await settle(tester);

    final json = jsonDecode(savedJsonFiles().single.readAsStringSync())
        as Map<String, dynamic>;
    final cover = json['cover'] as String;
    expect(cover, 'images/${json['id']}-cover.jpg');
    expect(File('${store.root.path}/$cover').existsSync(), isTrue);
  });
}
