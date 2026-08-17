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

/// Per-100g nutriment values. All optional — any field may be missing on OFF.
class OffNutriments {
  final double? energyKcal;
  final double? fat;
  final double? saturatedFat;
  final double? carbohydrates;
  final double? sugars;
  final double? proteins;
  final double? salt;

  const OffNutriments({
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.carbohydrates,
    this.sugars,
    this.proteins,
    this.salt,
  });
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
      nutriments: OffNutriments(
        energyKcal: _number(n['energy-kcal_100g']),
        fat: _number(n['fat_100g']),
        saturatedFat: _number(n['saturated-fat_100g']),
        carbohydrates: _number(n['carbohydrates_100g']),
        sugars: _number(n['sugars_100g']),
        proteins: _number(n['proteins_100g']),
        salt: _number(n['salt_100g']),
      ),
    );
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
