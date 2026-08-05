// Recipe file format v1 (spike/recipe.schema.json, decision D1 — ADR 0001
// candidate). Pure Dart: no Flutter imports in domain/.
//
// `raw` fields hold the user's original text and are never destroyed by
// parsing or editing; display falls back to raw when parsed fields are null.

class Recipe {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String title;
  final String? lang;
  final RecipeSource source;
  final Servings? servings;
  final RecipeTimes? times;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final List<String> tags;
  final String? notes;
  final Extraction? extraction;

  const Recipe({
    required this.schemaVersion,
    required this.id,
    required this.title,
    this.lang,
    required this.source,
    this.servings,
    this.times,
    required this.ingredients,
    required this.steps,
    this.tags = const [],
    this.notes,
    this.extraction,
  });

  /// Envelope split (architecture §3.3): the model emits content fields only;
  /// the app assembles the full file by stamping the envelope at save time.
  factory Recipe.assemble({
    required String id,
    required Map<String, dynamic> content,
    required List<String> originalImages,
    required DateTime importedAt,
    required String extractorModel,
    required String extractorMode,
  }) {
    final contentSource = content['source'];
    final contentExtraction = content['extraction'];
    return Recipe(
      schemaVersion: currentSchemaVersion,
      id: id,
      title: (content['title'] as String?) ?? '',
      lang: content['lang'] as String?,
      source: RecipeSource(
        type: 'screenshot',
        importedAt: importedAt.toIso8601String(),
        originalImages: originalImages,
        appHint: contentSource is Map ? contentSource['app_hint'] as String? : null,
      ),
      servings: Servings.fromJsonOrNull(content['servings']),
      times: RecipeTimes.fromJsonOrNull(content['times']),
      ingredients: [
        for (final i in (content['ingredients'] as List? ?? []))
          Ingredient.fromJson(i as Map<String, dynamic>)
      ],
      steps: [
        for (final s in (content['steps'] as List? ?? []))
          RecipeStep.fromJson(s as Map<String, dynamic>)
      ],
      tags: [for (final t in (content['tags'] as List? ?? [])) t as String],
      notes: null, // user's own field — extraction never touches it
      extraction: Extraction(
        model: extractorModel,
        mode: extractorMode,
        extractedAt: importedAt.toIso8601String(),
        overallConfidence: contentExtraction is Map
            ? (contentExtraction['overall_confidence'] as num?)?.toDouble()
            : null,
        needsReview: contentExtraction is Map
            ? [for (final p in (contentExtraction['needs_review'] as List? ?? [])) p as String]
            : const [],
      ),
    );
  }

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        schemaVersion: json['schema_version'] as int,
        id: json['id'] as String,
        title: json['title'] as String,
        lang: json['lang'] as String?,
        source: RecipeSource.fromJson(json['source'] as Map<String, dynamic>),
        servings: Servings.fromJsonOrNull(json['servings']),
        times: RecipeTimes.fromJsonOrNull(json['times']),
        ingredients: [
          for (final i in (json['ingredients'] as List? ?? []))
            Ingredient.fromJson(i as Map<String, dynamic>)
        ],
        steps: [
          for (final s in (json['steps'] as List? ?? []))
            RecipeStep.fromJson(s as Map<String, dynamic>)
        ],
        tags: [for (final t in (json['tags'] as List? ?? [])) t as String],
        notes: json['notes'] as String?,
        extraction: json['extraction'] is Map
            ? Extraction.fromJson(json['extraction'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'id': id,
        'title': title,
        'lang': lang,
        'source': source.toJson(),
        'servings': servings?.toJson(),
        'times': times?.toJson(),
        'ingredients': [for (final i in ingredients) i.toJson()],
        'steps': [for (final s in steps) s.toJson()],
        'tags': tags,
        'notes': notes,
        'extraction': extraction?.toJson(),
      };

  Recipe copyWith({
    String? title,
    String? notes,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    List<String>? tags,
  }) =>
      Recipe(
        schemaVersion: schemaVersion,
        id: id,
        title: title ?? this.title,
        lang: lang,
        source: source,
        servings: servings,
        times: times,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
        extraction: extraction,
      );
}

class RecipeSource {
  final String type;
  final String? importedAt;
  final List<String>? originalImages;
  final String? appHint;

  const RecipeSource({
    required this.type,
    this.importedAt,
    this.originalImages,
    this.appHint,
  });

  factory RecipeSource.fromJson(Map<String, dynamic> json) => RecipeSource(
        type: json['type'] as String? ?? 'screenshot',
        importedAt: json['imported_at'] as String?,
        originalImages: json['original_images'] is List
            ? [for (final p in json['original_images'] as List) p as String]
            : null,
        appHint: json['app_hint'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'imported_at': importedAt,
        'original_images': originalImages,
        'app_hint': appHint,
      };
}

class Servings {
  final num? amount;
  final String? raw;

  const Servings({this.amount, this.raw});

  static Servings? fromJsonOrNull(Object? json) => json is Map<String, dynamic>
      ? Servings(amount: json['amount'] as num?, raw: json['raw'] as String?)
      : null;

  Map<String, dynamic> toJson() => {'amount': amount, 'raw': raw};
}

class RecipeTimes {
  final num? prepMin;
  final num? cookMin;
  final num? totalMin;
  final String? raw;

  const RecipeTimes({this.prepMin, this.cookMin, this.totalMin, this.raw});

  static RecipeTimes? fromJsonOrNull(Object? json) => json is Map<String, dynamic>
      ? RecipeTimes(
          prepMin: json['prep_min'] as num?,
          cookMin: json['cook_min'] as num?,
          totalMin: json['total_min'] as num?,
          raw: json['raw'] as String?,
        )
      : null;

  Map<String, dynamic> toJson() =>
      {'prep_min': prepMin, 'cook_min': cookMin, 'total_min': totalMin, 'raw': raw};
}

class Ingredient {
  final String raw;
  final num? qty;
  final String? unit;
  final String? item;
  final String? note;
  final String? group;
  final double? confidence;

  const Ingredient({
    required this.raw,
    this.qty,
    this.unit,
    this.item,
    this.note,
    this.group,
    this.confidence,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) => Ingredient(
        raw: json['raw'] as String? ?? '',
        qty: json['qty'] as num?,
        unit: json['unit'] as String?,
        item: json['item'] as String?,
        note: json['note'] as String?,
        group: json['group'] as String?,
        confidence: (json['confidence'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'raw': raw,
        'qty': qty,
        'unit': unit,
        'item': item,
        'note': note,
        'group': group,
        'confidence': confidence,
      };

  Ingredient copyWith({String? raw}) => Ingredient(
        raw: raw ?? this.raw,
        qty: qty,
        unit: unit,
        item: item,
        note: note,
        group: group,
        confidence: confidence,
      );
}

class RecipeStep {
  final String raw;
  final double? confidence;

  const RecipeStep({required this.raw, this.confidence});

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        raw: json['raw'] as String? ?? '',
        confidence: (json['confidence'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {'raw': raw, 'confidence': confidence};

  RecipeStep copyWith({String? raw}) =>
      RecipeStep(raw: raw ?? this.raw, confidence: confidence);
}

class Extraction {
  final String? model;
  final String? mode; // "image" | "ocr_text"
  final String? extractedAt;
  final double? overallConfidence;
  final List<String> needsReview;

  const Extraction({
    this.model,
    this.mode,
    this.extractedAt,
    this.overallConfidence,
    this.needsReview = const [],
  });

  factory Extraction.fromJson(Map<String, dynamic> json) => Extraction(
        model: json['model'] as String?,
        mode: json['mode'] as String?,
        extractedAt: json['extracted_at'] as String?,
        overallConfidence: (json['overall_confidence'] as num?)?.toDouble(),
        needsReview: [
          for (final p in (json['needs_review'] as List? ?? [])) p as String
        ],
      );

  Map<String, dynamic> toJson() => {
        'model': model,
        'mode': mode,
        'extracted_at': extractedAt,
        'overall_confidence': overallConfidence,
        'needs_review': needsReview,
      };
}
