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

  /// Quantity label as printed on the pack, e.g. "1 L" — display text, never
  /// parsed (the raw-field stance from recipes).
  final String? quantity;

  /// 'off' (Open Food Facts) | 'manual'. Not pinned by validation — the
  /// recipe validator deliberately leaves source.type open (schema-additive).
  final String source;
  final String? addedAt;
  final Nutriments? nutriments;

  /// User's own photo of the product, relative like `images/<id>.jpg` —
  /// the recipe cover convention applied to the pantry. Absent in JSON
  /// unless set, so pre-photo files round-trip byte-identical.
  final String? image;

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
      };

  /// `image:` accepts a new ref, omission (keep), or [clearImage] (remove) —
  /// the recipe cover's tri-state rule.
  Product copyWith({
    String? name,
    String? brand,
    String? quantity,
    Nutriments? nutriments,
    String? image,
    bool clearImage = false,
  }) =>
      Product(
        schemaVersion: schemaVersion,
        barcode: barcode,
        name: name ?? this.name,
        brand: brand ?? this.brand,
        quantity: quantity ?? this.quantity,
        source: source,
        addedAt: addedAt,
        nutriments: nutriments ?? this.nutriments,
        image: clearImage ? null : (image ?? this.image),
      );
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
