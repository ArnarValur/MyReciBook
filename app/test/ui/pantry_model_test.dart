// PantryModel — the POC seam: scanned digits → OFF lookup → one product file.
// Covers the three-way outcome honestly (added / not-found / unavailable) and
// the null-store test seam. The scan screen itself has no widget test
// (platform channels on mount); the model IS the testable half.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/off_client.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/ui/pantry/pantry_model.dart';

String _foundBody() => jsonEncode({
      'code': '7038010071751',
      'status': 1,
      'product': {
        'product_name': 'Mellommelk 2,0% fett',
        'brands': 'Tine',
        'quantity': '1 L',
        'nutriments': {
          'energy-kcal_100g': 50,
          'fat_100g': 2,
          'carbohydrates_100g': 4.6,
          'proteins_100g': 3.5,
        },
      },
    });

OffClient _off(Future<http.Response> Function(http.Request) handler) =>
    OffClient(client: MockClient(handler), wait: (_) async {});

void main() {
  late Directory dir;
  late LocalPantryStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pantry_model_test');
    store = LocalPantryStore(dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('found: saves the product file and prepends it to the list', () async {
    final model = PantryModel(store,
        off: _off((_) async => http.Response(_foundBody(), 200)),
        clock: () => DateTime.utc(2026, 8, 17));
    await model.ensureLoaded();

    final outcome = await model.addByBarcode('7038010071751');

    expect(outcome, isA<PantryAdded>());
    expect((outcome as PantryAdded).wasKnown, isFalse);
    expect(outcome.product.name, 'Mellommelk 2,0% fett');
    expect(outcome.product.nutriments?.protein, 3.5);
    expect(model.products, hasLength(1));
    expect(File('${dir.path}/7038010071751.json').existsSync(), isTrue);
  });

  test('re-scan of a known barcode: wasKnown, one file, no duplicate',
      () async {
    final model = PantryModel(store,
        off: _off((_) async => http.Response(_foundBody(), 200)),
        clock: () => DateTime.utc(2026, 8, 17));
    await model.ensureLoaded();

    await model.addByBarcode('7038010071751');
    final second = await model.addByBarcode('7038010071751');

    expect((second as PantryAdded).wasKnown, isTrue);
    expect(model.products, hasLength(1));
    expect(
        dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')),
        hasLength(1));
  });

  test('status 0: PantryNotFound, nothing saved', () async {
    final model = PantryModel(store,
        off: _off((_) async =>
            http.Response('{"code":"5690123456789","status":0}', 200)));
    await model.ensureLoaded();

    final outcome = await model.addByBarcode('5690123456789');

    expect(outcome, isA<PantryNotFound>());
    expect(model.products, isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  test('persistent 5xx: PantryUnavailable, nothing saved', () async {
    final model = PantryModel(store,
        off: _off((_) async => http.Response('gateway sad', 502)));
    await model.ensureLoaded();

    final outcome = await model.addByBarcode('7038010071751');

    expect(outcome, isA<PantryUnavailable>());
    expect(model.products, isEmpty);
    expect(dir.listSync(), isEmpty);
  });

  test('null store (test seam): add works in-memory, remove too', () async {
    final model = PantryModel(null,
        off: _off((_) async => http.Response(_foundBody(), 200)));
    await model.ensureLoaded();

    final outcome = await model.addByBarcode('7038010071751');

    expect(outcome, isA<PantryAdded>());
    expect(model.products, hasLength(1));

    await model.remove('7038010071751');
    expect(model.products, isEmpty);
  });

  test('remove: deletes the file and the row', () async {
    final model = PantryModel(store,
        off: _off((_) async => http.Response(_foundBody(), 200)));
    await model.ensureLoaded();
    await model.addByBarcode('7038010071751');

    await model.remove('7038010071751');

    expect(model.products, isEmpty);
    expect(File('${dir.path}/7038010071751.json').existsSync(), isFalse);
  });
}
