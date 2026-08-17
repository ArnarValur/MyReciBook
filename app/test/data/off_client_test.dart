// OffClient against canned OFF v2 payloads: the three-way outcome split
// (FOUND / NOT_FOUND / UNAVAILABLE — "not in the database" must never look
// like "the request failed"), retry-on-UNAVAILABLE-only with injected wait,
// timeout, and missing-nutriment tolerance on crowdsourced data.

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/off_client.dart';

// Realistic v2 FOUND body — fat is an int, carbs a double, on purpose:
// OFF serves both and the parser must accept both.
const _foundBody = '''
{
  "code": "7038010013966",
  "product": {
    "product_name": "Mellommelk 2,0% fett",
    "brands": "Tine",
    "quantity": "1 L",
    "nutriments": {
      "energy-kcal_100g": 50,
      "fat_100g": 2,
      "saturated-fat_100g": 1.3,
      "carbohydrates_100g": 4.6,
      "sugars_100g": 4.6,
      "proteins_100g": 3.5,
      "salt_100g": 0.1
    }
  },
  "status": 1,
  "status_verbose": "product found"
}
''';

const _notFoundBody = '''
{"code": "0000000000000", "status": 0, "status_verbose": "product not found"}
''';

/// Client whose wait() is instant and recorded — retry tests stay fast.
OffClient _client(MockClient mock,
        {List<Duration>? waits, Duration? timeout}) =>
    OffClient(
      client: mock,
      timeout: timeout ?? const Duration(seconds: 10),
      wait: (d) async => waits?.add(d),
    );

void main() {
  test('FOUND: parses product and per-100g nutriments, int and double', () async {
    late http.Request seen;
    final client = _client(MockClient((req) async {
      seen = req;
      return http.Response.bytes(utf8.encode(_foundBody), 200,
          headers: {'content-type': 'application/json'});
    }));

    final result = await client.lookup('7038010013966');

    expect(seen.method, 'GET');
    expect(seen.url.toString(),
        'https://world.openfoodfacts.org/api/v2/product/7038010013966.json?fields=product_name%2Cbrands%2Cquantity%2Cnutriments');
    // OFF requires an identifying UA on every request.
    expect(seen.headers['User-Agent'],
        'MyReciBook/0.5 (arnarvalurjonsson@gmail.com)');

    final found = result as OffFound;
    final p = found.product;
    expect(p.barcode, '7038010013966');
    expect(p.name, 'Mellommelk 2,0% fett');
    expect(p.brands, 'Tine');
    expect(p.quantity, '1 L');
    expect(p.nutriments.energyKcal, 50.0);
    expect(p.nutriments.fat, 2.0); // int in JSON
    expect(p.nutriments.saturatedFat, 1.3);
    expect(p.nutriments.carbohydrates, 4.6); // double in JSON
    expect(p.nutriments.sugars, 4.6);
    expect(p.nutriments.proteins, 3.5);
    expect(p.nutriments.salt, 0.1);
  });

  test('NOT_FOUND: HTTP 200 with status 0', () async {
    var requests = 0;
    final client = _client(MockClient((req) async {
      requests++;
      return http.Response(_notFoundBody, 200);
    }));

    expect(await client.lookup('0000000000000'), isA<OffNotFound>());
    expect(requests, 1, reason: 'NOT_FOUND is definitive — no retry');
  });

  test('NOT_FOUND: HTTP 404', () async {
    final client = _client(MockClient((req) async {
      return http.Response('not found', 404);
    }));

    expect(await client.lookup('123'), isA<OffNotFound>());
  });

  test('UNAVAILABLE retry: 429 then success', () async {
    var requests = 0;
    final waits = <Duration>[];
    final client = _client(MockClient((req) async {
      requests++;
      if (requests == 1) return http.Response('slow down', 429);
      return http.Response.bytes(utf8.encode(_foundBody), 200);
    }), waits: waits);

    final result = await client.lookup('7038010013966');

    expect(result, isA<OffFound>());
    expect(requests, 2);
    expect(waits, hasLength(1), reason: 'one backoff between the two tries');
    expect(waits.single, greaterThanOrEqualTo(const Duration(seconds: 1)));
  });

  test('UNAVAILABLE: persistent 5xx gives up after 2 tries', () async {
    var requests = 0;
    final client = _client(MockClient((req) async {
      requests++;
      return http.Response('boom', 503);
    }));

    final result = await client.lookup('123');

    expect(result, isA<OffUnavailable>());
    expect((result as OffUnavailable).message, contains('503'));
    expect(requests, 2);
  });

  test('UNAVAILABLE: timeout — never confused with NOT_FOUND', () async {
    var requests = 0;
    final client = _client(
      MockClient((req) async {
        requests++;
        // Never answers — only the lookup's own timeout ends the attempt.
        return Completer<http.Response>().future;
      }),
      timeout: const Duration(milliseconds: 50),
    );

    final result = await client.lookup('123');

    expect(result, isA<OffUnavailable>());
    expect((result as OffUnavailable).message, contains('no response'));
    expect(requests, 2, reason: 'timeout is transient — retried once');
  });

  test('UNAVAILABLE: network error', () async {
    final client = _client(MockClient((req) async {
      throw http.ClientException('connection refused');
    }));

    expect(await client.lookup('123'), isA<OffUnavailable>());
  });

  test('UNAVAILABLE: unparseable 200 body', () async {
    final client = _client(MockClient((req) async {
      return http.Response('<html>captive portal</html>', 200);
    }));

    expect(await client.lookup('123'), isA<OffUnavailable>());
  });

  test('FOUND: missing nutriments and fields tolerated (crowdsourced)', () async {
    final client = _client(MockClient((req) async {
      return http.Response(
          '{"status": 1, "product": {"product_name": "Mystery snack"}}', 200);
    }));

    final result = await client.lookup('999') as OffFound;
    final p = result.product;
    expect(p.name, 'Mystery snack');
    expect(p.brands, isNull);
    expect(p.quantity, isNull);
    expect(p.nutriments.energyKcal, isNull);
    expect(p.nutriments.fat, isNull);
    expect(p.nutriments.salt, isNull);
  });

  test('FOUND: partial nutriments — present parse, absent stay null', () async {
    final client = _client(MockClient((req) async {
      return http.Response(
          '{"status": 1, "product": {"product_name": "Halfdata", '
          '"nutriments": {"fat_100g": 12, "proteins_100g": "7.5"}}}',
          200);
    }));

    final result = await client.lookup('998') as OffFound;
    expect(result.product.nutriments.fat, 12.0);
    expect(result.product.nutriments.proteins, 7.5); // string-typed number
    expect(result.product.nutriments.carbohydrates, isNull);
    expect(result.product.nutriments.energyKcal, isNull);
  });
}
