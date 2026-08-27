// What came back from reading a product label, after we stopped trusting it.
//
// The model is asked to omit anything it cannot read (assets/label_prompt.md
// rule 1), because the pantry's own rule is that a blank field means "not
// measured" and never zero. This file is the second half of that promise: it
// drops anything that is not a finite, sane number rather than letting a
// hallucinated 999 g of salt reach a form the person will tap Save on.
//
// Nothing here writes a product. The read fills a FORM, the person confirms
// it, and the existing save path does the rest — so a bad read costs a
// correction, never a wrong file.

import 'product.dart';

/// Where the per-100 g numbers came from, which decides how loudly the UI
/// should ask the person to check them.
enum LabelBasis {
  /// The label printed per 100 g and we used it.
  printed,

  /// The label printed per serving only; we scaled by its stated gram weight.
  converted,

  /// No usable per-100 g figures. Name and serving may still be good.
  unknown,
}

class LabelRead {
  const LabelRead({
    this.name,
    this.brand,
    this.values = const {},
    this.serving,
    this.basis = LabelBasis.unknown,
    this.confidence,
    this.unreadable = const [],
    this.noLabel = false,
  });

  final String? name;
  final String? brand;

  /// Per 100 g, keyed as the product file keys them. Only what survived.
  final Map<String, double> values;

  final Serving? serving;
  final LabelBasis basis;

  /// 0.0–1.0 as the model rated its own reading; null when it did not say.
  final double? confidence;

  /// Fields the model could see were there but could not read — the list the
  /// person should check by hand.
  final List<String> unreadable;

  /// No packaging text to read at all — a blank surface, a face, a photo too
  /// dark to make anything out. Deliberately NOT "this is not food": whether
  /// a thing belongs in someone's pantry is their call, and the model would
  /// get it wrong anyway (coffee, spices, oil and supplements all read as
  /// non-food to a model looking for a nutrition table).
  final bool noLabel;

  bool get isEmpty =>
      name == null && brand == null && values.isEmpty && serving == null;

  /// A reading worth showing at all. Low confidence still shows — the person
  /// is looking at the pack and can fix it — but a read with nothing in it is
  /// a failed read, not a form to confirm.
  bool get hasAnything => !noLabel && !isEmpty;
}

/// Keys the pantry form and the product file understand. Anything else the
/// model returns is kept only if it looks like a plain nutrient key, so a
/// label that prints calcium survives without this list having to know about
/// calcium.
const _knownKeys = {
  'kcal',
  'fat',
  'saturated_fat',
  'carbs',
  'sugars',
  'fiber',
  'protein',
  'salt',
};

/// Ceilings per 100 g. Nothing edible exceeds these, so a value past one is a
/// misread decimal point or an invented number — dropped either way. kcal is
/// capped a little above pure fat (900) to leave room for an honest rounding.
const _ceilings = {
  'kcal': 950.0,
  'fat': 100.0,
  'saturated_fat': 100.0,
  'carbs': 100.0,
  'sugars': 100.0,
  'fiber': 100.0,
  'protein': 100.0,
  'salt': 100.0,
};

double? _number(Object? v) {
  final d = v is num ? v.toDouble() : double.tryParse('$v'.trim());
  if (d == null || !d.isFinite || d < 0) return null;
  return d;
}

String? _text(Object? v) {
  if (v is! String) return null;
  final t = v.trim();
  return t.isEmpty || t.length > 120 ? null : t;
}

LabelBasis _basis(Object? v) => switch (v) {
      'printed' => LabelBasis.printed,
      'converted' => LabelBasis.converted,
      _ => LabelBasis.unknown,
    };

/// Turn the model's JSON into a reading, dropping everything that fails a
/// sanity check. Never throws: a garbled response is an empty read.
LabelRead labelReadFromJson(Map<String, dynamic> json) {
  // Both keys: 'not_a_product' was the first prompt's wording and a model
  // that has seen it may still answer that way.
  if (json['no_label'] == true || json['not_a_product'] == true) {
    return const LabelRead(noLabel: true);
  }

  final values = <String, double>{};
  final raw = json['per_100g'];
  if (raw is Map) {
    for (final e in raw.entries) {
      final key = '${e.key}'.trim().toLowerCase();
      if (key.isEmpty || key.length > 40) continue;
      // A key we do not know is kept only if it reads like a nutrient name;
      // this is how vitamins and minerals ride along without a list.
      if (!_knownKeys.contains(key) &&
          !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key)) {
        continue;
      }
      final n = _number(e.value);
      if (n == null) continue;
      final ceiling = _ceilings[key];
      if (ceiling != null && n > ceiling) continue;
      values[key] = n;
    }
  }

  // Macros that add up to more than a hundred grams of a hundred grams is a
  // misread table, not a food. Keep the reading but drop the numbers — the
  // name and the serving are usually still right.
  final mass = ['fat', 'carbs', 'protein', 'fiber']
      .fold<double>(0, (sum, k) => sum + (values[k] ?? 0));
  if (mass > 105) {
    values.removeWhere((k, _) => k != 'kcal');
  }

  Serving? serving;
  final s = json['serving'];
  if (s is Map) {
    final label = _text(s['label']);
    final grams = _number(s['grams']);
    if (label != null && grams != null && grams > 0 && grams <= 2000) {
      serving = Serving(label: label, grams: grams);
    }
  }

  final conf = _number(json['confidence']);
  return LabelRead(
    name: _text(json['name']),
    brand: _text(json['brand']),
    values: values,
    serving: serving,
    basis: values.isEmpty ? LabelBasis.unknown : _basis(json['basis']),
    confidence: conf != null && conf <= 1 ? conf : null,
    // `as List?` would throw on a model that answered with a bare string —
    // and this whole file exists so a strange response is an empty read.
    unreadable: [
      for (final u in (json['unreadable'] is List
          ? json['unreadable'] as List
          : const []))
        if (_text(u) case final String t) t
    ],
  );
}

/// The reading as a Nutriments map, for the form to prefill from.
Nutriments? labelNutriments(LabelRead read) =>
    read.values.isEmpty ? null : Nutriments.fromMap(read.values);
