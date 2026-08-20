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
import 'package:myrecibook/domain/product.dart';
import 'package:myrecibook/domain/starter_foods.dart';
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

/// A product file as an older build wrote it: the seven label macros only,
/// no vitamins, plus the user's own photo — the exact shape of the 46 files
/// already on the phone.
void _seedOldFile(Directory dir, String barcode,
    {String name = 'Mellommelk 2,0% fett', bool edited = false}) {
  File('${dir.path}/$barcode.json').writeAsStringSync(jsonEncode({
    'schema_version': 1,
    'barcode': barcode,
    'name': name,
    'brand': 'Tine',
    'quantity': '1 L',
    'source': 'off',
    'added_at': '2026-08-17T10:00:00.000Z',
    'nutriments': {'kcal': 50.0, 'fat': 2.0, 'carbs': 4.6, 'protein': 3.5},
    'image': 'images/$barcode.jpg',
    if (edited) 'user_edited': true,
  }));
}

/// The same product as OFF actually answers today: macros AND the minerals
/// and vitamins the old file never kept.
String _richBody(String barcode) => jsonEncode({
      'code': barcode,
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
          'calcium_100g': 0.118,
          'vitamin-d_100g': 0.0000008,
          'iodine_100g': 0.000019,
        },
      },
    });

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

  group('refreshAll — the 46 already on the phone', () {
    const code = '7038010071751';

    test('an old seven-macro file gains the vitamins, keeps photo and date',
        () async {
      _seedOldFile(dir, code);
      final model = PantryModel(store,
          off: _off((_) async => http.Response(_richBody(code), 200)),
          wait: (_) async {});
      await model.ensureLoaded();
      expect(model.products.single.nutriments?.values, hasLength(4));

      final report = await model.refreshAll();

      expect(report.updated, 1);
      expect(report.unchanged, 0);
      expect(report.failed, 0);
      final n = model.products.single.nutriments!;
      expect(n['calcium'], 0.118);
      expect(n['vitamin_d'], 0.0000008);
      expect(n['iodine'], 0.000019);
      // The user's own photo and the day they added it are not OFF's to
      // overwrite — a refresh must never cost them either.
      expect(model.products.single.image, 'images/$code.jpg');
      expect(model.products.single.addedAt, '2026-08-17T10:00:00.000Z');
      // ...and it landed on disk, not just in memory.
      final onDisk = jsonDecode(File('${dir.path}/$code.json').readAsStringSync())
          as Map<String, dynamic>;
      expect((onDisk['nutriments'] as Map)['calcium'], 0.118);
    });

    test('a file OFF agrees with is counted unchanged and never rewritten',
        () async {
      _seedOldFile(dir, code);
      final model = PantryModel(store,
          off: _off((_) async => http.Response(_richBody(code), 200)),
          wait: (_) async {});
      await model.ensureLoaded();
      await model.refreshAll();
      final stamp = File('${dir.path}/$code.json').lastModifiedSync();

      final second = await model.refreshAll();

      expect(second.unchanged, 1);
      expect(second.updated, 0);
      expect(File('${dir.path}/$code.json').lastModifiedSync(), stamp);
    });

    test('offline: counted failed, the file is left exactly as it was',
        () async {
      _seedOldFile(dir, code);
      final model = PantryModel(store,
          off: _off((_) async => http.Response('gateway sad', 502)),
          wait: (_) async {});
      await model.ensureLoaded();

      final report = await model.refreshAll();

      expect(report.failed, 1);
      expect(report.updated, 0);
      expect(model.products.single.nutriments?.values, hasLength(4));
    });

    test('barcode gone from OFF: counted missing, nothing lost', () async {
      _seedOldFile(dir, code);
      final model = PantryModel(store,
          off: _off((_) async => http.Response('{"status":0}', 200)),
          wait: (_) async {});
      await model.ensureLoaded();

      final report = await model.refreshAll();

      expect(report.missing, 1);
      expect(model.products.single.name, 'Mellommelk 2,0% fett');
      expect(model.products.single.nutriments?.values, hasLength(4));
    });

    test('a mixed shelf: every product asked once, order kept', () async {
      _seedOldFile(dir, '111', name: 'Alpha');
      _seedOldFile(dir, '222', name: 'Beta');
      _seedOldFile(dir, '333', name: 'Gamma');
      final asked = <String>[];
      final model = PantryModel(store, wait: (_) async {},
          off: _off((req) async {
        final code = req.url.pathSegments.last.replaceAll('.json', '');
        asked.add(code);
        // Only the middle one is still known to OFF.
        return code == '222'
            ? http.Response(_richBody('222'), 200)
            : http.Response('{"status":0}', 200);
      }));
      await model.ensureLoaded();
      final orderBefore = model.products.map((p) => p.id).toList();

      final report = await model.refreshAll();

      expect(asked.toSet(), {'111', '222', '333'});
      expect(report.total, 3);
      expect(report.updated, 1);
      expect(report.missing, 2);
      // A refresh must not reshuffle the shelf the way a fresh scan does.
      expect(model.products.map((p) => p.id).toList(), orderBefore);
    });

    test('progress counts up and clears when the sweep ends', () async {
      _seedOldFile(dir, '111', name: 'Alpha');
      _seedOldFile(dir, '222', name: 'Beta');
      final seen = <String>[];
      final model = PantryModel(store,
          off: _off((_) async => http.Response('{"status":0}', 200)),
          wait: (_) async {});
      await model.ensureLoaded();
      model.addListener(() =>
          seen.add('${model.refreshing}:${model.refreshDone}/${model.refreshTotal}'));

      await model.refreshAll();

      expect(seen.first, 'true:0/2');
      expect(seen, contains('true:1/2'));
      expect(seen.last, 'false:2/2');
      expect(model.refreshing, isFalse);
    });

    test('empty shelf: no lookups, an honest zero report', () async {
      var calls = 0;
      final model = PantryModel(store, wait: (_) async {}, off: _off((_) async {
        calls++;
        return http.Response(_richBody(code), 200);
      }));
      await model.ensureLoaded();

      final report = await model.refreshAll();

      expect(calls, 0);
      expect(report.total, 0);
      expect(model.refreshableCount, 0);
    });
  });

  group('userEdited — a hand-save outranks the bulk refresh', () {
    const code = '7038010071751';

    test('upsert marks the file as the user\'s and it round-trips', () async {
      final model = PantryModel(store,
          off: _off((_) async => http.Response('unused', 500)));
      await model.ensureLoaded();

      final saved = await model.upsert(const Product(
        schemaVersion: Product.currentSchemaVersion,
        barcode: code,
        name: 'Mellommelk, corrected by hand',
        source: 'manual',
      ));

      expect(saved.userEdited, isTrue);
      // ...and the flag survives the disk round-trip, not just this session.
      final reloaded = PantryModel(store,
          off: _off((_) async => http.Response('unused', 500)));
      await reloaded.ensureLoaded();
      expect(reloaded.products.single.userEdited, isTrue);
    });

    test('refreshAll walks past an edited file: untouched, counted nowhere',
        () async {
      _seedOldFile(dir, '111', name: 'Alpha', edited: true);
      _seedOldFile(dir, '222', name: 'Beta');
      final asked = <String>[];
      final model = PantryModel(store, wait: (_) async {},
          off: _off((req) async {
        asked.add(req.url.pathSegments.last.replaceAll('.json', ''));
        return http.Response(_richBody('222'), 200);
      }));
      await model.ensureLoaded();
      expect(model.refreshableCount, 1);
      expect(model.editedCount, 1);
      final stamp = File('${dir.path}/111.json').lastModifiedSync();

      final report = await model.refreshAll();

      expect(asked, ['222']);
      // The edited product lands in NO bucket — "1 skipped" is the dialog's
      // job before the sweep, not the report's after it.
      expect(report.total, 1);
      expect(report.updated, 1);
      expect(File('${dir.path}/111.json').lastModifiedSync(), stamp);
      expect(model.byId('111')!.name, 'Alpha');
    });

    test('refreshOne is the deliberate door: overwrites and clears the flag',
        () async {
      _seedOldFile(dir, code, edited: true);
      final model = PantryModel(store,
          off: _off((_) async => http.Response(_richBody(code), 200)));
      await model.ensureLoaded();

      final outcome = await model.refreshOne(code);

      expect(outcome, isA<PantryAdded>());
      expect((outcome as PantryAdded).wasKnown, isTrue);
      expect(outcome.product.userEdited, isFalse);
      expect(outcome.product.nutriments?['calcium'], 0.118);
      // The cleared flag is on disk too — the NEXT bulk refresh may touch it.
      final onDisk = jsonDecode(
              File('${dir.path}/$code.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(onDisk['user_edited'], isNull);
      expect(model.refreshableCount, 1);
    });

    test('refreshOne on a barcodeless product: PantryUnavailable, no lookup',
        () async {
      var calls = 0;
      final model = PantryModel(store, off: _off((_) async {
        calls++;
        return http.Response(_richBody(code), 200);
      }));
      await model.ensureLoaded();
      final saved = await model.upsert(const Product(
        schemaVersion: Product.currentSchemaVersion,
        barcode: '',
        name: 'Homemade bread',
        source: 'manual',
      ));

      final outcome = await model.refreshOne(saved.id);

      expect(outcome, isA<PantryUnavailable>());
      expect((outcome as PantryUnavailable).message, contains('no barcode'));
      expect(calls, 0);
    });
  });

  group('servings from Open Food Facts', () {
    test('a scanned pack arrives with its own portion preselected', () async {
      final model = PantryModel(
          null,
          off: _off((_) async => http.Response(
              jsonEncode({
                'code': '1',
                'status': 1,
                'product': {
                  'product_name': 'Havregryn',
                  'serving_size': '1 dl (35 g)',
                  'serving_quantity': 35,
                  'nutriments': {'energy-kcal_100g': 370},
                },
              }),
              200)));

      final outcome = await model.addByBarcode('1');
      final product = (outcome as PantryAdded).product;

      expect(product.servings.single.label, '1 dl (35 g)');
      expect(product.servings.single.grams, 35);
      expect(product.preferredServing.grams, 35);
      // 100 g stays one tap away.
      expect(product.servingOptions.map((s) => s.grams), [35, 100]);
    });

    test('a pack with no serving weight still logs at 100 g', () async {
      final model = PantryModel(
          null,
          off: _off((_) async => http.Response(
              jsonEncode({
                'code': '1',
                'status': 1,
                'product': {
                  'product_name': 'Havregryn',
                  'nutriments': {'energy-kcal_100g': 370},
                },
              }),
              200)));

      final product = (await model.addByBarcode('1') as PantryAdded).product;
      expect(product.servings, isEmpty);
      expect(product.defaultServing, isNull);
      expect(product.preferredServing.grams, 100);
    });
  });

  group('auto-category from Open Food Facts', () {
    String milkWithGroups(String barcode) => jsonEncode({
          'code': barcode,
          'status': 1,
          'product': {
            'product_name': 'Mellommelk 2,0% fett',
            'brands': 'Tine',
            'nutriments': {'energy-kcal_100g': 50},
            'food_groups_tags': [
              'en:milk-and-dairy-products',
              'en:milk-and-yogurt'
            ],
            'categories_tags': ['en:dairies', 'en:milks'],
          },
        });

    test('a scanned milk arrives already wearing Dairy', () async {
      final model = PantryModel(store,
          off: _off((_) async =>
              http.Response(milkWithGroups('7038010071751'), 200)),
          clock: () => DateTime.utc(2026, 8, 20));
      await model.ensureLoaded();

      final outcome = await model.addByBarcode('7038010071751');

      expect((outcome as PantryAdded).product.tags, ['Dairy']);
      final onDisk = jsonDecode(
              File('${dir.path}/7038010071751.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(onDisk['tags'], ['Dairy']);
    });

    test('a scan OFF has no classification for saves with no tag', () async {
      final model = PantryModel(store,
          off: _off((_) async => http.Response(_foundBody(), 200)),
          clock: () => DateTime.utc(2026, 8, 20));
      await model.ensureLoaded();

      final outcome = await model.addByBarcode('7038010071751');

      expect((outcome as PantryAdded).product.tags, isEmpty);
    });

    test('refreshAll fills the tag on an old untagged file', () async {
      _seedOldFile(dir, '7038010071751');
      final model = PantryModel(store,
          off: _off((_) async =>
              http.Response(milkWithGroups('7038010071751'), 200)),
          wait: (_) async {});
      await model.ensureLoaded();

      final report = await model.refreshAll();

      expect(report.updated, 1);
      expect(model.byId('7038010071751')!.tags, ['Dairy']);
    });

    test('refreshAll never touches tags the user already chose', () async {
      _seedOldFile(dir, '7038010071751');
      final store2 = LocalPantryStore(dir);
      final seeded = PantryModel(store2, off: _off((_) async => fail('no')));
      await seeded.ensureLoaded();
      // Tag it by hand THROUGH the store, then clear the edited flag so the
      // sweep still visits the file — isolating the tag-fill rule itself.
      await store2.save(seeded
          .byId('7038010071751')!
          .copyWith(tags: ['Breakfast'], userEdited: false));

      final model = PantryModel(store,
          off: _off((_) async =>
              http.Response(milkWithGroups('7038010071751'), 200)),
          wait: (_) async {});
      await model.ensureLoaded();
      await model.refreshAll();

      expect(model.byId('7038010071751')!.tags, ['Breakfast']);
    });
  });

  group('starter foods', () {
    test('import adds files; a re-import skips everything', () async {
      final model = PantryModel(store,
          off: _off((_) async => fail('no lookup')),
          clock: () => DateTime.utc(2026, 8, 20));
      await model.ensureLoaded();
      final pack = starterPackages[0];

      final first = await model.addStarterFoods(pack.foods);
      expect(first.added, pack.foods.length);
      expect(first.skipped, 0);
      expect(File('${dir.path}/carrot.json').existsSync(), isTrue);

      final second = await model.addStarterFoods(pack.foods);
      expect(second.added, 0);
      expect(second.skipped, pack.foods.length);
    });

    test('an existing food is never overwritten by the import', () async {
      final model = PantryModel(store,
          off: _off((_) async => fail('no lookup')),
          clock: () => DateTime.utc(2026, 8, 20));
      await model.ensureLoaded();
      // The user's own Carrot, hand-made before the import.
      await model.upsert(Product(
          schemaVersion: 1,
          barcode: '',
          name: 'Carrot',
          source: 'manual',
          nutriments: Nutriments(kcal: 99)));

      await model.addStarterFoods(starterPackages[0].foods);

      final carrot = model.byId('carrot')!;
      expect(carrot.nutriments?.kcal, 99);
      expect(carrot.userEdited, isTrue);
    });
  });
}
