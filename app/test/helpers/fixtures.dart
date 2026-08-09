// Shared recipe fixtures (review 2026-08-09: byte-identical builders were
// copy-pasted per file, and the strict-inference sweep missed one copy —
// exactly the drift this file prevents). Only the IDENTICAL builders live
// here; a test file with a genuinely different shape keeps its own local
// builder next to the assertions that depend on it.

import 'package:myrecibook/domain/recipe.dart';

/// The standard two-ingredient, two-step extraction (app_flow/boot_flow
/// shape): flour's 0.6 confidence keeps one low-confidence line in play.
Map<String, dynamic> canned({String title = 'Pancakes', bool withSteps = true}) =>
    {
      'title': title,
      'ingredients': [
        {'raw': '2 eggs', 'qty': 2, 'item': 'eggs', 'confidence': 0.95},
        {'raw': '1 cup flour', 'confidence': 0.6},
      ],
      'steps': withSteps
          ? [
              {'raw': 'Mix everything.', 'confidence': 0.9},
              {'raw': 'Fry until golden.', 'confidence': 0.9},
            ]
          : <Object?>[],
      'extraction': {'overall_confidence': 0.9, 'needs_review': <Object?>[]},
    };

Recipe cannedRecipe(String id, String title) => Recipe.assemble(
      id: id,
      content: canned(title: title),
      originalImages: const [],
      importedAt: DateTime.utc(2026, 8, 6),
      extractorModel: 'fake-model',
      extractorMode: 'image',
    );

/// What the extractor returns for a non-recipe screenshot (D5 fail path).
Map<String, dynamic> notARecipe() => {
      'title': '',
      'ingredients': <Object?>[],
      'steps': <Object?>[],
      'extraction': {'overall_confidence': 0.1, 'needs_review': <Object?>[]},
    };

/// One ingredient line with only the fields the test cares about present.
Map<String, dynamic> ing(String raw, {num? qty, String? unit, String? item}) =>
    {
      'raw': raw,
      'qty': ?qty,
      'unit': ?unit,
      'item': ?item,
      'confidence': 0.9,
    };
