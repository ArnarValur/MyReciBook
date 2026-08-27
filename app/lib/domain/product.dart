// Pantry product file format v1 — one <stem>.json per product in the user's
// own storage, the recipe file stance (arch §3/§4) applied to the food base.
// Pure Dart: no Flutter imports in domain/.
//
// Open Food Facts data is crowdsourced: any nutriment can be missing, so
// every per-100g field is optional and fromJson tolerates absent keys.

class Product {
  static const int currentSchemaVersion = 1;

  final int schemaVersion;

  /// Empty for manual products — the stem falls back to a name slug then.
  final String barcode;
  final String name;
  final String? brand;

  /// The pack size as printed, e.g. "1 L", "400 ml" — the product page's
  /// SIZE field. Display text, never parsed (the raw-field stance from
  /// recipes). Open Food Facts fills it on a scan; the user may type over it
  /// or empty it, and empty means absent, not "".
  final String? quantity;

  /// 'off' (Open Food Facts) | 'manual'. Not pinned by validation — the
  /// recipe validator deliberately leaves source.type open (schema-additive).
  final String source;
  final String? addedAt;
  final Nutriments? nutriments;

  /// Named portions the user can log, e.g. "1 dl" = 35 g, "1 medium" = 182 g.
  /// The MFP mechanic: pick a serving, type how many. Empty is fine — every
  /// product still offers 100 g and a free gram amount ([servingOptions]).
  /// Absent from JSON when empty, so pre-serving files round-trip unchanged.
  final List<Serving> servings;

  /// Index into [servings] that the log sheet should preselect. Out-of-range
  /// or absent falls back to the first option.
  final int? defaultServing;

  /// The user typed or corrected this product's data by hand. A bulk
  /// Open Food Facts refresh must never overwrite it (Arnar, 2026-08-19);
  /// only a deliberate per-product refresh may, and that clears the flag.
  /// Absent from JSON when false, so older files round-trip unchanged.
  final bool userEdited;

  /// User-chosen groups — "Dairy", "Wine", anything. Free strings, never an
  /// enum: [productTagSuggestions] seeds the picker, custom tags are equals.
  /// Absent from JSON when empty.
  final List<String> tags;

  /// User's own photo of the product, relative like `images/<id>.jpg` —
  /// the recipe cover convention applied to the pantry. Absent in JSON
  /// unless set, so pre-photo files round-trip byte-identical.
  final String? image;

  /// Search aliases — "Paprika" finds Bell Pepper. Starter foods ship with
  /// Norwegian names here; hand-created products may carry any. Absent from
  /// JSON when empty (schema-additive).
  final List<String> synonyms;

  const Product({
    required this.schemaVersion,
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity,
    required this.source,
    this.addedAt,
    this.nutriments,
    this.image,
    this.servings = const [],
    this.defaultServing,
    this.userEdited = false,
    this.tags = const [],
    this.synonyms = const [],
  });

  /// Store identity and filename stem: the barcode when scanned, else a slug
  /// of the name. A second save of the same barcode lands on the same file —
  /// update, never a duplicate.
  String get id => barcode.isNotEmpty ? barcode : slugifyProductName(name);

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        schemaVersion: json['schema_version'] as int,
        barcode: json['barcode'] as String? ?? '',
        name: json['name'] as String,
        brand: json['brand'] as String?,
        quantity: json['quantity'] as String?,
        source: json['source'] as String? ?? 'manual',
        addedAt: json['added_at'] as String?,
        nutriments: Nutriments.fromJsonOrNull(json['nutriments']),
        image: json['image'] as String?,
        servings: Serving.listFromJson(json['servings']),
        defaultServing: (json['default_serving'] as num?)?.toInt(),
        userEdited: json['user_edited'] as bool? ?? false,
        tags: [
          for (final t in (json['tags'] as List? ?? []))
            if (t is String && t.trim().isNotEmpty) t
        ],
        synonyms: [
          for (final s in (json['synonyms'] as List? ?? []))
            if (s is String && s.trim().isNotEmpty) s
        ],
      );

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'barcode': barcode,
        'name': name,
        'brand': brand,
        'quantity': quantity,
        'source': source,
        'added_at': addedAt,
        'nutriments': nutriments?.toJson(),
        if (image != null) 'image': image,
        if (servings.isNotEmpty)
          'servings': [for (final s in servings) s.toJson()],
        if (defaultServing != null) 'default_serving': defaultServing,
        if (userEdited) 'user_edited': true,
        if (tags.isNotEmpty) 'tags': tags,
        if (synonyms.isNotEmpty) 'synonyms': synonyms,
      };

  /// `image:`, `brand:` and `quantity:` accept a new value, omission (keep),
  /// or their clear flag (remove) — the recipe cover's tri-state rule. The
  /// clear flags exist because the product page is the file: a field the user
  /// empties has to leave the JSON, not sit there as "".
  Product copyWith({
    String? name,
    String? brand,
    bool clearBrand = false,
    String? quantity,
    bool clearQuantity = false,
    Nutriments? nutriments,
    String? image,
    bool clearImage = false,
    List<Serving>? servings,
    int? defaultServing,
    bool? userEdited,
    List<String>? tags,
    List<String>? synonyms,
  }) =>
      Product(
        schemaVersion: schemaVersion,
        barcode: barcode,
        name: name ?? this.name,
        brand: clearBrand ? null : (brand ?? this.brand),
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        source: source,
        addedAt: addedAt,
        nutriments: nutriments ?? this.nutriments,
        image: clearImage ? null : (image ?? this.image),
        servings: servings ?? this.servings,
        defaultServing: defaultServing ?? this.defaultServing,
        userEdited: userEdited ?? this.userEdited,
        tags: tags ?? this.tags,
        synonyms: synonyms ?? this.synonyms,
      );

  /// What the log sheet offers: the product's own portions first, then the
  /// universal 100 g. Never empty — a bare scanned product is still loggable,
  /// which is the whole point of "add the fruit that has no barcode".
  List<Serving> get servingOptions {
    final options = [for (final s in servings) s];
    if (!options.any((s) => s.grams == 100)) {
      options.add(const Serving(label: '100 g', grams: 100));
    }
    return options;
  }

  /// The preselected portion — [defaultServing] when it points somewhere
  /// real, else the first option.
  Serving get preferredServing {
    final options = servingOptions;
    final i = defaultServing;
    if (i != null && i >= 0 && i < options.length) return options[i];
    return options.first;
  }
}

/// One named portion of a product: a label a human recognises and the grams
/// it weighs. Grams are the bridge — nutriments are stored per 100 g, so any
/// portion with a weight can be costed exactly (diary.dart's snapshot).
class Serving {
  final String label;
  final double grams;

  const Serving({required this.label, required this.grams});

  factory Serving.fromJson(Map<String, dynamic> json) => Serving(
        label: json['label'] as String,
        grams: (json['grams'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'label': label, 'grams': grams};

  /// Tolerant list read: a malformed entry is dropped, never fatal (§7).
  static List<Serving> listFromJson(Object? json) {
    if (json is! List) return const [];
    final out = <Serving>[];
    for (final row in json) {
      if (row is! Map) continue;
      final label = row['label'];
      final grams = row['grams'];
      if (label is! String || label.isEmpty) continue;
      if (grams is! num || grams <= 0) continue;
      out.add(Serving(label: label, grams: grams.toDouble()));
    }
    return out;
  }

  /// "125 g" — the free-form amount the log sheet builds when the user types
  /// grams instead of picking a portion.
  factory Serving.grams(double grams) =>
      Serving(label: '${_trimGrams(grams)} g', grams: grams);

  static String _trimGrams(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '');
  }
}

/// Per-100 g values, an OPEN map — Open Food Facts sends vitamins and
/// minerals too, and hand-corrected products can carry anything. The seven
/// label macros keep their original JSON keys so files written by older
/// builds round-trip unchanged; everything else is stored alongside them.
///
/// Units: `kcal` is kilocalories, `energy_kj` kilojoules, and every other
/// value is GRAMS per 100 g — exactly how Open Food Facts stores them
/// (calcium 0.118 means 118 mg). Display converts; storage never does.
class Nutriments {
  /// Canonical keys for the seven values printed on a nutrition label, in
  /// the order a label prints them.
  static const macroKeys = [
    'kcal',
    'fat',
    'saturated_fat',
    'carbs',
    'sugars',
    'protein',
    'salt',
  ];

  final Map<String, double> values;

  /// Open construction — any key, any number of them.
  const Nutriments.fromMap(this.values);

  /// The seven label macros by name. Kept because most call sites only ever
  /// mean these; extras go through [Nutriments.fromMap].
  Nutriments({
    double? kcal,
    double? fat,
    double? saturatedFat,
    double? carbs,
    double? sugars,
    double? protein,
    double? salt,
  }) : values = {
          'kcal': ?kcal,
          'fat': ?fat,
          'saturated_fat': ?saturatedFat,
          'carbs': ?carbs,
          'sugars': ?sugars,
          'protein': ?protein,
          'salt': ?salt,
        };

  double? operator [](String key) => values[key];

  double? get kcal => values['kcal'];
  double? get fat => values['fat'];
  double? get saturatedFat => values['saturated_fat'];
  double? get carbs => values['carbs'];
  double? get sugars => values['sugars'];
  double? get protein => values['protein'];
  double? get salt => values['salt'];

  bool get isEmpty => values.isEmpty;

  /// Every value times [factor] — per-100 g to per-serving, or a serving to a
  /// row total. Linear by construction: nutrition labels scale, so the diary
  /// never needs to re-fetch anything.
  Nutriments scaled(double factor) => Nutriments.fromMap({
        for (final e in values.entries) e.key: e.value * factor,
      });

  /// Key-wise sum. A key only one side carries is kept — see
  /// diary.dart's sumNutriments for why that is the honest choice.
  Nutriments plus(Nutriments other) {
    final merged = Map<String, double>.from(values);
    other.values.forEach((k, v) => merged[k] = (merged[k] ?? 0) + v);
    return Nutriments.fromMap(merged);
  }

  /// Keys that are not one of the seven label macros — vitamins, minerals,
  /// and anything a user typed in themselves. Sorted for a stable UI.
  List<String> get extraKeys =>
      (values.keys.where((k) => !macroKeys.contains(k)).toList())..sort();

  /// Older files stored exactly seven nullable keys; newer ones store any
  /// number. Both read the same way: every numeric entry is a value, nulls
  /// are dropped.
  static Nutriments? fromJsonOrNull(Object? json) {
    if (json is! Map) return null;
    final values = <String, double>{};
    json.forEach((key, value) {
      if (key is! String) return;
      final number = value is num ? value.toDouble() : null;
      if (number != null) values[key] = number;
    });
    return Nutriments.fromMap(values);
  }

  /// Writes every value it holds. Absent keys stay absent — no null padding,
  /// so a product that only has calcium does not gain six empty macros.
  Map<String, dynamic> toJson() => {
        for (final key in macroKeys)
          if (values.containsKey(key)) key: values[key],
        for (final key in extraKeys) key: values[key],
      };
}

/// Filesystem-safe stem for manual products: lowercase, non-alphanumeric runs
/// collapse to one '-'. Never empty — an all-symbol name still gets a valid
/// filename (and passes RecipeStore.safeId by construction).
String slugifyProductName(String name) {
  final slug = name
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return slug.isEmpty ? 'product' : slug;
}

/// Problems in a complete product file — validate.dart's fileProblems pattern
/// for the pantry. Never save a file that doesn't validate (architecture §7).
List<String> productProblems(Map<String, dynamic> json) {
  final problems = <String>[];
  for (final field in ['schema_version', 'name', 'source']) {
    if (!json.containsKey(field) || json[field] == null) {
      problems.add('missing:$field');
    }
  }
  if (json['schema_version'] != null && json['schema_version'] != 1) {
    problems.add('unknown schema_version ${json['schema_version']}');
  }
  final name = json['name'];
  if (name is! String || name.isEmpty) problems.add('empty name');
  return problems;
}
