// Round-trip tests over the spike's golden outputs (T3 step 2, grill P7).
// Fixtures predate the original_images amendment: their stale singular
// "source.original_image" key must be tolerated and come out null.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/domain/validate.dart';

Map<String, dynamic> loadFixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  for (final name in [
    'screenshot1.json',
    'screenshot2.json',
    'example-recipe.json',
  ]) {
    group(name, () {
      test('fromJson preserves every known field', () {
        final json = loadFixture(name);
        final r = Recipe.fromJson(json);

        expect(r.schemaVersion, json['schema_version']);
        expect(r.id, json['id']);
        expect(r.title, json['title']);
        expect(r.lang, json['lang']);

        final src = json['source'] as Map<String, dynamic>;
        expect(r.source.type, src['type']);
        expect(r.source.importedAt, src['imported_at']);
        // Stale singular key in the fixture — unknown to the parser.
        expect(r.source.originalImages, src['original_images']);
        expect(r.source.appHint, src['app_hint']);

        final servings = json['servings'] as Map<String, dynamic>?;
        if (servings == null) {
          expect(r.servings, isNull);
        } else {
          expect(r.servings!.amount, servings['amount']);
          expect(r.servings!.raw, servings['raw']);
        }

        final times = json['times'] as Map<String, dynamic>?;
        if (times == null) {
          expect(r.times, isNull);
        } else {
          expect(r.times!.prepMin, times['prep_min']);
          expect(r.times!.cookMin, times['cook_min']);
          expect(r.times!.totalMin, times['total_min']);
          expect(r.times!.raw, times['raw']);
        }

        final ings = json['ingredients'] as List;
        expect(r.ingredients, hasLength(ings.length));
        for (var i = 0; i < ings.length; i++) {
          final j = ings[i] as Map<String, dynamic>;
          final ing = r.ingredients[i];
          expect(ing.raw, j['raw'], reason: 'ingredients[$i].raw');
          expect(ing.qty, j['qty'], reason: 'ingredients[$i].qty');
          expect(ing.unit, j['unit'], reason: 'ingredients[$i].unit');
          expect(ing.item, j['item'], reason: 'ingredients[$i].item');
          expect(ing.note, j['note'], reason: 'ingredients[$i].note');
          expect(ing.group, j['group'], reason: 'ingredients[$i].group');
          expect(ing.confidence, (j['confidence'] as num?)?.toDouble(),
              reason: 'ingredients[$i].confidence');
        }

        final steps = json['steps'] as List;
        expect(r.steps, hasLength(steps.length));
        for (var i = 0; i < steps.length; i++) {
          final j = steps[i] as Map<String, dynamic>;
          expect(r.steps[i].raw, j['raw'], reason: 'steps[$i].raw');
          expect(r.steps[i].confidence, (j['confidence'] as num?)?.toDouble(),
              reason: 'steps[$i].confidence');
        }

        expect(r.tags, json['tags']);
        expect(r.notes, json['notes']);

        final ext = json['extraction'] as Map<String, dynamic>?;
        if (ext == null) {
          expect(r.extraction, isNull);
        } else {
          expect(r.extraction!.model, ext['model']);
          expect(r.extraction!.mode, ext['mode']);
          expect(r.extraction!.extractedAt, ext['extracted_at']);
          expect(r.extraction!.overallConfidence,
              (ext['overall_confidence'] as num?)?.toDouble());
          expect(r.extraction!.needsReview, ext['needs_review'] ?? const <Object?>[]);
        }
      });

      test('toJson matches the fixture on every known field', () {
        final json = loadFixture(name);
        final out = Recipe.fromJson(json).toJson();

        expect(out['schema_version'], json['schema_version']);
        expect(out['id'], json['id']);
        expect(out['title'], json['title']);
        expect(out['lang'], json['lang']);
        expect(out['servings'], json['servings']);
        expect(out['times'], json['times']);
        expect(out['ingredients'], json['ingredients']);
        expect(out['steps'], json['steps']);
        expect(out['tags'], json['tags']);
        expect(out['notes'], json['notes']);
        expect(out['extraction'], json['extraction']);
        final src = json['source'] as Map<String, dynamic>;
        final outSrc = out['source'] as Map<String, dynamic>;
        expect(outSrc['type'], src['type']);
        expect(outSrc['imported_at'], src['imported_at']);
        expect(outSrc['original_images'], src['original_images']);
        expect(outSrc['app_hint'], src['app_hint']);
      });

      test('second round-trip is byte-identical', () {
        final first = Recipe.fromJson(loadFixture(name)).toJson();
        final second = Recipe.fromJson(first).toJson();
        expect(second, first);
        expect(jsonEncode(second), jsonEncode(first));
      });
    });
  }

  group('Recipe.assemble', () {
    final content = <String, dynamic>{
      'title': 'Pancakes',
      'lang': 'en',
      'source': {'app_hint': 'instagram'},
      'servings': {'amount': 4, 'raw': 'serves 4'},
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs'},
        {'raw': '250 g flour'},
      ],
      'steps': [
        {'raw': 'Mix.', 'confidence': 0.9},
      ],
      'tags': ['breakfast'],
      'notes': 'model must not set this', // sneaks in — forced null
      'extraction': {
        'overall_confidence': 0.87,
        'needs_review': ['servings'],
      },
    };
    final importedAt = DateTime.utc(2026, 8, 6, 12, 30);
    final r = Recipe.assemble(
      id: 'abc-123',
      content: content,
      originalImages: ['images/abc-123-1.jpg', 'images/abc-123-2.png'],
      importedAt: importedAt,
      extractorModel: 'gemini-3.5-flash-lite',
      extractorMode: 'image',
    );

    test('stamps the envelope', () {
      expect(r.schemaVersion, 1);
      expect(r.id, 'abc-123');
      expect(r.source.type, 'screenshot');
      expect(r.source.importedAt, importedAt.toIso8601String());
      expect(r.source.originalImages,
          ['images/abc-123-1.jpg', 'images/abc-123-2.png']);
      expect(r.source.appHint, 'instagram');
      expect(r.extraction!.model, 'gemini-3.5-flash-lite');
      expect(r.extraction!.mode, 'image');
      expect(r.extraction!.extractedAt, importedAt.toIso8601String());
      expect(r.extraction!.overallConfidence, 0.87);
      expect(r.extraction!.needsReview, ['servings']);
    });

    test('carries content through and forces notes null', () {
      expect(r.title, 'Pancakes');
      expect(r.lang, 'en');
      expect(r.servings!.amount, 4);
      expect(r.servings!.raw, 'serves 4');
      expect(r.ingredients.map((i) => i.raw), ['2 eggs', '250 g flour']);
      expect(r.ingredients[0].qty, 2);
      expect(r.steps.single.raw, 'Mix.');
      expect(r.steps.single.confidence, 0.9);
      expect(r.tags, ['breakfast']);
      expect(r.notes, isNull);
    });
  });

  // Pins the schema-additive source.type value "manual" (T3 batch/manual
  // slice): no extraction, no images — old files unaffected, new ones must
  // survive the round-trip and pass validation.
  group('manual file', () {
    final manual = Recipe(
      schemaVersion: Recipe.currentSchemaVersion,
      id: 'manual-1',
      title: "Nan's bread",
      source: const RecipeSource(
          type: 'manual', importedAt: '2026-08-06T20:00:00.000'),
      servings: const Servings(raw: '6 servings'),
      ingredients: const [
        Ingredient(raw: '2 cups flour'),
        Ingredient(raw: '1 tsp salt'),
      ],
      steps: const [RecipeStep(raw: 'Mix.'), RecipeStep(raw: 'Bake.')],
    );

    test('round-trips byte-identical with type manual and no extraction', () {
      final json = manual.toJson();
      expect((json['source'] as Map)['type'], 'manual');
      expect((json['source'] as Map)['original_images'], isNull);
      expect(json['extraction'], isNull);

      final back = Recipe.fromJson(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);
      expect(back.source.type, 'manual');
      expect(back.extraction, isNull);
      expect(jsonEncode(back.toJson()), jsonEncode(json));
    });

    test('validator does not pin source.type — nothing blocks the save', () {
      expect(fileProblems(manual.toJson()).where(isSaveBlocking), isEmpty);
    });
  });

  group('copyWith', () {
    final base = Recipe.fromJson(loadFixture('example-recipe.json'));

    test('changes only what was passed', () {
      final edited = base.copyWith(title: 'New title', notes: 'my note');
      expect(edited.title, 'New title');
      expect(edited.notes, 'my note');
      // Untouched fields survive: full JSON equal except the two edits.
      final expected = base.toJson()
        ..['title'] = 'New title'
        ..['notes'] = 'my note';
      expect(edited.toJson(), expected);
    });

    test('no args = identical output', () {
      expect(base.copyWith().toJson(), base.toJson());
    });

    test('replaces lists without touching the rest', () {
      final edited = base.copyWith(
        ingredients: [base.ingredients.first.copyWith(raw: '300 g hveiti')],
        steps: [base.steps.first.copyWith(raw: 'Blandið öllu saman.')],
        tags: ['pancakes'],
      );
      expect(edited.ingredients.single.raw, '300 g hveiti');
      expect(edited.ingredients.single.item, base.ingredients.first.item);
      expect(edited.steps.single.raw, 'Blandið öllu saman.');
      expect(edited.steps.single.confidence, base.steps.first.confidence);
      expect(edited.tags, ['pancakes']);
      expect(edited.id, base.id);
      expect(edited.source.toJson(), base.source.toJson());
      expect(edited.extraction!.toJson(), base.extraction!.toJson());
    });
  });
}
