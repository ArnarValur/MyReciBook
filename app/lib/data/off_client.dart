// Open Food Facts lookup — barcode → product name/brand/quantity + per-100g
// nutriments, for the pantry track. OFF is crowdsourced: EVERY parsed field is
// optional, and numbers arrive as int or double depending on who typed them in.
//
// The three outcomes are a sealed result, not exceptions, because callers must
// never confuse "not in the database" (offer manual entry, don't retry) with
// "the request failed" (offline banner, retry later) — the 2026-08-17 shell
// spike burned us exactly there:
//   OffFound        parsed product data
//   OffNotFound     HTTP 200 with "status":0, or 404
//   OffUnavailable  transport error, timeout, 429/5xx, unparseable body
//
// UNAVAILABLE (only) is retried once with a short backoff, AuthedClient-style
// (remote_store.dart): injectable wait for tests, timeout on every attempt.
// OFF requires an identifying User-Agent — sent on every request.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Everything Open Food Facts holds per 100 g — the seven label macros AND
/// the vitamins and minerals, which it sends for most branded products.
///
/// Keys are ours, not OFF's: the seven macros use the names the product file
/// has always used, and every other nutrient keeps OFF's own name with
/// hyphens turned into underscores (`vitamin-d` -> `vitamin_d`).
///
/// Units are OFF's: `kcal` in kilocalories, `energy_kj` in kilojoules,
/// everything else in GRAMS (calcium 0.118 = 118 mg). No conversion here.
class OffNutriments {
  final Map<String, double> values;

  const OffNutriments([this.values = const {}]);

  double? operator [](String key) => values[key];

  double? get energyKcal => values['kcal'];
  double? get fat => values['fat'];
  double? get saturatedFat => values['saturated_fat'];
  double? get carbohydrates => values['carbs'];
  double? get sugars => values['sugars'];
  double? get proteins => values['protein'];
  double? get salt => values['salt'];

  bool get isEmpty => values.isEmpty;
}

/// One OFF product. Everything except [barcode] is optional — crowdsourced.
class OffProduct {
  final String barcode;
  final String? name; // product_name
  final String? brands;
  final String? quantity; // e.g. '1 L'
  final OffNutriments nutriments;

  const OffProduct({
    required this.barcode,
    this.name,
    this.brands,
    this.quantity,
    this.nutriments = const OffNutriments(),
  });
}

/// Outcome of [OffClient.lookup]. Exhaustive — switch on it.
sealed class OffLookupResult {
  const OffLookupResult();
}

/// The barcode is in the database; [product] holds whatever fields it has.
class OffFound extends OffLookupResult {
  final OffProduct product;

  const OffFound(this.product);
}

/// OFF answered and the barcode is NOT in the database. Definitive —
/// retrying won't help; offer manual entry instead.
class OffNotFound extends OffLookupResult {
  const OffNotFound();
}

/// We never got a usable answer: offline, timeout, 429/5xx, garbage body.
/// Transient — the same lookup may succeed later.
class OffUnavailable extends OffLookupResult {
  final String message;

  const OffUnavailable(this.message);

  @override
  String toString() => 'OffUnavailable: $message';
}

class OffClient {
  OffClient({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    Future<void> Function(Duration)? wait,
  })  : _client = client ?? http.Client(),
        _wait = wait ?? ((d) => Future<void>.delayed(d));

  static const _base = 'https://world.openfoodfacts.org/api/v2/product';
  static const _fields = 'product_name,brands,quantity,nutriments';

  /// OFF requires an identifying UA — anonymous clients get blocked.
  static const userAgent = 'MyReciBook/0.5 (arnarvalurjonsson@gmail.com)';

  /// Total attempts on UNAVAILABLE (FOUND/NOT_FOUND return immediately).
  static const _maxTries = 2;
  static const _retryDelay = Duration(seconds: 3);

  final Duration timeout;
  final http.Client _client;
  final Future<void> Function(Duration) _wait;

  /// Looks up [barcode] on Open Food Facts. Never throws — every failure
  /// mode is an [OffUnavailable], retried once before giving up.
  Future<OffLookupResult> lookup(String barcode) async {
    var tries = 0;
    while (true) {
      final result = await _attempt(barcode);
      if (result is! OffUnavailable) return result;
      tries++;
      if (tries >= _maxTries) return result;
      await _wait(_retryDelay);
    }
  }

  Future<OffLookupResult> _attempt(String barcode) async {
    final uri = Uri.parse('$_base/$barcode.json')
        .replace(queryParameters: {'fields': _fields});
    final http.Response resp;
    try {
      resp = await _client
          .get(uri, headers: {'User-Agent': userAgent}).timeout(timeout);
    } on TimeoutException {
      return OffUnavailable('no response after ${timeout.inSeconds} s');
    } on http.ClientException catch (e) {
      return OffUnavailable('offline: ${e.message}');
    } on IOException catch (e) {
      // SocketException, HandshakeException (captive portals), ...
      return OffUnavailable('offline: $e');
    }

    if (resp.statusCode == 404) return const OffNotFound();
    if (resp.statusCode != 200) {
      // 429/5xx and anything else unexpected: the answer didn't arrive.
      return OffUnavailable('HTTP ${resp.statusCode}');
    }

    final Map<String, dynamic> body;
    try {
      // bodyBytes + utf8: package:http falls back to latin1 without a charset
      // header, which mojibakes 'Mellommelk 2,0%'-class names (rule 7).
      body = jsonDecode(utf8.decode(resp.bodyBytes, allowMalformed: true))
          as Map<String, dynamic>;
    } catch (e) {
      return OffUnavailable('unparseable body: $e');
    }

    // v2 not-found: HTTP 200, {"status": 0, "status_verbose": "..."}.
    if (body['status'] == 0) return const OffNotFound();

    final product = body['product'];
    if (product is! Map) {
      return OffUnavailable('no product object in 200 body');
    }
    return OffFound(_parseProduct(barcode, product.cast<String, dynamic>()));
  }

  OffProduct _parseProduct(String barcode, Map<String, dynamic> p) {
    final rawNutriments = p['nutriments'];
    final n = rawNutriments is Map
        ? rawNutriments.cast<String, dynamic>()
        : const <String, dynamic>{};
    return OffProduct(
      barcode: barcode,
      name: _string(p['product_name']),
      brands: _string(p['brands']),
      quantity: _string(p['quantity']),
      nutriments: OffNutriments(_parseNutriments(n)),
    );
  }

  /// OFF's nutrient name -> ours, for the ones the product file already
  /// names. Anything not listed keeps OFF's name with '-' as '_'.
  static const _renamed = {
    'energy-kcal': 'kcal',
    'saturated-fat': 'saturated_fat',
    'carbohydrates': 'carbs',
    'proteins': 'protein',
    'energy-kj': 'energy_kj',
  };

  /// Not nutrients. OFF mixes scores and estimates into the same object, and
  /// showing "nova group: 1 g" next to calcium would be nonsense.
  static const _notNutrients = {
    'energy', // duplicate of energy-kj, in kJ, under a name that reads as kcal
    'nova-group',
    'nutrition-score-fr',
    'nutrition-score-uk',
    'fruits-vegetables-legumes-estimate-from-ingredients',
    'fruits-vegetables-nuts-estimate-from-ingredients',
    'carbon-footprint-from-known-ingredients',
    'carbon-footprint-from-known-ingredients-product',
  };

  /// Every per-100 g nutrient OFF sent, keyed our way. OFF repeats each
  /// nutrient under several suffixes (`_serving`, `_value`, `_unit`, bare);
  /// only the `_100g` ones are read, so serving-size numbers can never leak
  /// in as if they were per-100 g.
  static Map<String, double> _parseNutriments(Map<String, dynamic> n) {
    final out = <String, double>{};
    for (final entry in n.entries) {
      final key = entry.key;
      if (!key.endsWith('_100g')) continue;
      final offName = key.substring(0, key.length - '_100g'.length);
      if (_notNutrients.contains(offName)) continue;
      final value = _number(entry.value);
      if (value == null) continue;
      out[_renamed[offName] ?? offName.replaceAll('-', '_')] = value;
    }
    return out;
  }

  static String? _string(Object? v) =>
      v is String && v.isNotEmpty ? v : null;

  // int and double both occur in OFF JSON; the odd string-typed number too.
  static double? _number(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
