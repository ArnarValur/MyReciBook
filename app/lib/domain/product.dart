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

  const Product({
    required this.schemaVersion,
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity,
    required this.source,
    this.addedAt,
    this.nutriments,
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
      };

  Product copyWith({
    String? name,
    String? brand,
    String? quantity,
    Nutriments? nutriments,
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
      );
}

/// Per-100g values. All optional doubles — Open Food Facts fills whatever the
/// crowd typed in, which is often not everything.
class Nutriments {
  final double? kcal;
  final double? fat;
  final double? saturatedFat;
  final double? carbs;
  final double? sugars;
  final double? protein;
  final double? salt;

  const Nutriments({
    this.kcal,
    this.fat,
    this.saturatedFat,
    this.carbs,
    this.sugars,
    this.protein,
    this.salt,
  });

  static Nutriments? fromJsonOrNull(Object? json) => json is Map<String, dynamic>
      ? Nutriments(
          kcal: (json['kcal'] as num?)?.toDouble(),
          fat: (json['fat'] as num?)?.toDouble(),
          saturatedFat: (json['saturated_fat'] as num?)?.toDouble(),
          carbs: (json['carbs'] as num?)?.toDouble(),
          sugars: (json['sugars'] as num?)?.toDouble(),
          protein: (json['protein'] as num?)?.toDouble(),
          salt: (json['salt'] as num?)?.toDouble(),
        )
      : null;

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'fat': fat,
        'saturated_fat': saturatedFat,
        'carbs': carbs,
        'sugars': sugars,
        'protein': protein,
        'salt': salt,
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
