// BatchModel unit tests: strict sequential worker (technical rule 4), the
// auto-save / hold / skip / fail taxonomy, held-content retry, and the
// attention count that backs the drawer badge.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/ui/batch_model.dart';

/// Immediate outcomes, consumed in order; last repeats. Map = success,
/// ExtractionException = throw.
class FakeExtractor implements Extractor {
  FakeExtractor(this.outcomes);

  final List<Object> outcomes;
  int calls = 0;
  final List<List<String>> callImages = [];

  @override
  String get mode => 'image';

  @override
  String get modelName => 'fake-model';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    final o = outcomes[calls < outcomes.length ? calls : outcomes.length - 1];
    calls++;
    callImages.add([for (final f in images) f.path]);
    if (o is ExtractionException) throw o;
    return jsonDecode(jsonEncode(o)) as Map<String, dynamic>;
  }
}

/// Gated variant: each call parks on a completer until released, recording
/// how many extractions ever run concurrently.
class GatedExtractor extends FakeExtractor {
  GatedExtractor(super.outcomes);

  final List<Completer<void>> gates = [];
  int active = 0;
  int maxActive = 0;

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    active++;
    if (active > maxActive) maxActive = active;
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    active--;
    return super.extractContent(images);
  }
}

Map<String, dynamic> content({
  String title = 'Pancakes',
  double overall = 0.9,
  List<String> needsReview = const [],
  bool withSteps = true,
  double lineConfidence = 0.95,
}) =>
    {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'confidence': lineConfidence},
        {'raw': '1 cup flour', 'confidence': lineConfidence},
      ],
      'steps': withSteps
          ? [
              {'raw': 'Mix everything.', 'confidence': 0.9},
            ]
          : <Object?>[],
      'extraction': {'overall_confidence': overall, 'needs_review': needsReview},
    };

Map<String, dynamic> notARecipe() => {
      'title': '',
      'ingredients': <Object?>[],
      'steps': <Object?>[],
      'extraction': {'overall_confidence': 0.1, 'needs_review': <Object?>[]},
    };

void main() {
  late Directory tmp;
  late List<File> picks;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_batch_model');
    picks = [];
    for (var i = 1; i <= 3; i++) {
      final f = File('${tmp.path}/pick$i.jpg');
      await f.writeAsBytes([i]);
      picks.add(f);
    }
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  /// Records saves; envelope comes back unchanged (the store contract of
  /// returning the completed recipe is irrelevant to the model's logic).
  (List<Recipe>, List<List<File>>, Future<Recipe> Function(Recipe, List<File>))
      recordingSave() {
    final recipes = <Recipe>[];
    final images = <List<File>>[];
    Future<Recipe> save(Recipe r, List<File> imgs) async {
      recipes.add(r);
      images.add(imgs);
      return r;
    }

    return (recipes, images, save);
  }

  test('worker is strictly sequential and preserves queue order', () async {
    final extractor = GatedExtractor([content()]);
    final (saved, _, save) = recordingSave();
    final model = BatchModel(extractor: extractor, save: save);

    model.addAll([
      [picks[0]],
      [picks[1]],
      [picks[2]],
    ]);
    await Future<void>.delayed(Duration.zero);
    // Only the first extraction has started; the rest wait in line.
    expect(extractor.gates, hasLength(1));
    expect(model.items[0].state, BatchItemState.extracting);
    expect(model.items[1].state, BatchItemState.waiting);

    extractor.gates[0].complete();
    await Future<void>.delayed(Duration.zero);
    expect(extractor.gates, hasLength(2));
    expect(model.items[0].state, BatchItemState.saved);
    expect(model.items[1].state, BatchItemState.extracting);

    extractor.gates[1].complete();
    await Future<void>.delayed(Duration.zero);
    extractor.gates[2].complete();
    await model.whenIdle;

    expect(extractor.maxActive, 1); // never parallel (rule 4)
    expect(extractor.callImages,
        [for (final p in picks) [p.path]]); // FIFO order preserved
    expect(saved, hasLength(3));
  });

  test('high confidence auto-saves with needs_review flags kept in the file',
      () async {
    final (saved, savedImages, save) = recordingSave();
    final model = BatchModel(
      extractor: FakeExtractor([
        content(overall: 0.92, needsReview: ['ingredients[1]'])
      ]),
      save: save,
    );
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;

    final item = model.items.single;
    expect(item.state, BatchItemState.saved);
    expect(item.recipe, isNotNull);
    // Review-later hook: the flag survives the auto-save.
    expect(saved.single.extraction!.needsReview, ['ingredients[1]']);
    expect(saved.single.toJson()['extraction']['needs_review'],
        ['ingredients[1]']);
    expect(savedImages.single, [picks[0]]); // cached picks ride along
    expect(model.attention, 0);
  });

  test('overall confidence under the bar holds the item with its content',
      () async {
    final (saved, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([content(title: 'Pasta', overall: 0.5)]),
        save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;

    final item = model.items.single;
    expect(item.state, BatchItemState.needsReview);
    expect(item.content!['title'], 'Pasta');
    expect(saved, isEmpty); // nothing written without eyes on it
    expect(model.attention, 1);
  });

  test('missing overall confidence is not high confidence — held', () async {
    final (saved, _, save) = recordingSave();
    final c = content()..remove('extraction');
    final model = BatchModel(extractor: FakeExtractor([c]), save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;
    expect(model.items.single.state, BatchItemState.needsReview);
    expect(saved, isEmpty);
  });

  test('empty steps hold for review even at high confidence', () async {
    final (saved, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([content(withSteps: false, overall: 0.95)]),
        save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;
    expect(model.items.single.state, BatchItemState.needsReview);
    expect(saved, isEmpty);
  });

  test('save-blocking content (empty title) holds for review', () async {
    final (saved, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([content(title: '', overall: 0.95)]),
        save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;
    expect(model.items.single.state, BatchItemState.needsReview);
    expect(saved, isEmpty);
  });

  test('not-a-recipe (empty shell) skips honestly, saves nothing', () async {
    final (saved, _, save) = recordingSave();
    final model =
        BatchModel(extractor: FakeExtractor([notARecipe()]), save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;

    expect(model.items.single.state, BatchItemState.skipped);
    expect(saved, isEmpty);
    expect(model.attention, 0); // a skip demands no action
    expect(model.skippedCount, 1);
  });

  test('transport failure → failed with copy; retry re-extracts and saves',
      () async {
    final extractor = FakeExtractor([
      ExtractionException('offline: no route to host'),
      content(title: 'Waffles'),
    ]);
    final (saved, _, save) = recordingSave();
    final model = BatchModel(extractor: extractor, save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;

    final item = model.items.single;
    expect(item.state, BatchItemState.failed);
    expect(item.error, 'offline · retry when connected');
    expect(model.attention, 1);

    model.retry(item);
    await model.whenIdle;
    expect(item.state, BatchItemState.saved);
    expect(extractor.calls, 2); // content was null → real re-extract
    expect(saved.single.title, 'Waffles');
    expect(model.attention, 0);
  });

  test('429 and generic failures get their own captions', () async {
    final (_, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([
          ExtractionException('quota', httpStatus: 429),
          ExtractionException('unparseable model response: x'),
        ]),
        save: save);
    model.addAll([
      [picks[0]],
      [picks[1]],
    ]);
    await model.whenIdle;
    expect(model.items[0].error, 'rate-limited · retry in a minute');
    expect(model.items[1].error, 'failed · tap retry');
  });

  test('failed save keeps the extraction; retry skips the AI call', () async {
    final extractor = FakeExtractor([content(title: 'Soup')]);
    var failSave = true;
    final saved = <Recipe>[];
    final model = BatchModel(
      extractor: extractor,
      save: (r, imgs) async {
        if (failSave) throw StateError('disk full');
        saved.add(r);
        return r;
      },
    );
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;

    final item = model.items.single;
    expect(item.state, BatchItemState.failed);
    expect(item.error, "couldn't save to your folder · tap retry");
    expect(item.content, isNotNull); // the held retry artifact

    failSave = false;
    model.retry(item);
    await model.whenIdle;
    expect(item.state, BatchItemState.saved);
    expect(extractor.calls, 1); // no second AI call burned
    expect(saved.single.title, 'Soup');
  });

  test('markReviewed flips a held item to saved and clears its attention',
      () async {
    final (_, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([content(overall: 0.4)]), save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;
    final item = model.items.single;
    expect(model.attention, 1);

    final reviewed = Recipe.fromJson(Recipe.assemble(
      id: 'r-1',
      content: content(),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 6),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    ).toJson());
    model.markReviewed(item, reviewed);
    expect(item.state, BatchItemState.saved);
    expect(item.reviewed, isTrue);
    expect(item.recipe, reviewed);
    expect(model.attention, 0);
  });

  test('flaggedLines counts low-confidence and needs_review lines once each',
      () async {
    final (_, _, save) = recordingSave();
    final c = {
      'title': 'Curry',
      'ingredients': [
        {'raw': '1 tsp? salt', 'confidence': 0.5}, // low AND flagged — 1 line
        {'raw': '2 onions', 'confidence': 0.95},
      ],
      'steps': [
        {'raw': 'Fry.', 'confidence': 0.95},
      ],
      'extraction': {
        'overall_confidence': 0.5,
        'needs_review': ['ingredients[0].qty', 'steps[0]'],
      },
    };
    final model = BatchModel(extractor: FakeExtractor([c]), save: save);
    model.addAll([
      [picks[0]]
    ]);
    await model.whenIdle;
    expect(model.items.single.flaggedLines, 2); // ingredient 0 + step 0
  });

  test('clearFinished drops saved and skipped; attention items stay', () async {
    final (_, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([
          content(),
          notARecipe(),
          content(overall: 0.3),
          ExtractionException('offline: x'),
        ]),
        save: save);
    model.addAll([for (final p in picks.take(3)) [p]]);
    model.addAll([
      [picks[0]]
    ]); // 4th item — note: addAll sweeps finished, but nothing finished yet
    await model.whenIdle;

    expect(model.items, hasLength(4));
    model.clearFinished();
    expect([for (final i in model.items) i.state],
        [BatchItemState.needsReview, BatchItemState.failed]);
    expect(model.attention, 2);

    model.removeItem(model.items.first);
    expect(model.items, hasLength(1));
    expect(model.attention, 1);
  });

  test('a new batch sweeps finished noise but keeps attention items',
      () async {
    final (_, _, save) = recordingSave();
    final model = BatchModel(
        extractor: FakeExtractor([
          content(), // saved
          content(overall: 0.2), // held
          content(title: 'Fresh'), // second batch
        ]),
        save: save);
    model.addAll([
      [picks[0]],
      [picks[1]],
    ]);
    await model.whenIdle;
    expect(model.savedCount, 1);

    model.addAll([
      [picks[2]]
    ]);
    await model.whenIdle;
    // The saved item was swept; the held one and the new one remain.
    expect(model.items, hasLength(2));
    expect(model.items[0].state, BatchItemState.needsReview);
    expect(model.items[1].state, BatchItemState.saved);
  });
}
