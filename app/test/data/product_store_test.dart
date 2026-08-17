// LocalPantryStore against real temp dirs — hostile-folder behaviour is
// architecture §7: foreign/corrupt files are counted skipped, never fatal.
// The pantry twist: the filename stem IS the identity (barcode or name
// slug), so "save the same barcode again" must overwrite, never duplicate.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/domain/product.dart';

Product validProduct(String barcode, String name,
        {String? addedAt, Nutriments? nutriments}) =>
    Product(
      schemaVersion: 1,
      barcode: barcode,
      name: name,
      source: barcode.isEmpty ? 'manual' : 'off',
      addedAt: addedAt,
      nutriments: nutriments,
    );

void main() {
  late Directory root;
  late LocalPantryStore store;
  final cleanup = <Directory>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('recibook_pantry_test');
    cleanup.add(root);
    store = LocalPantryStore(root);
  });

  tearDown(() async {
    for (final dir in cleanup) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    cleanup.clear();
  });

  group('listAll', () {
    test('missing root → empty, zero skipped', () async {
      final result =
          await LocalPantryStore(Directory('${root.path}/does-not-exist'))
              .listAll();
      expect(result.products, isEmpty);
      expect(result.skipped, 0);
    });

    test('hostile folder: foreign and corrupt files skipped, valid load',
        () async {
      await store.save(
          validProduct('111', 'Milk', addedAt: '2026-08-17T10:00:00Z'));
      await File('${root.path}/notes.txt').writeAsString('not a product');
      await File('${root.path}/broken.json').writeAsString('{not json at all');
      await File('${root.path}/foreign.json')
          .writeAsString(jsonEncode({'some': 'other app'}));

      final result = await store.listAll();
      expect(result.products.map((p) => p.id), ['111']);
      // .txt is ignored outright; the two bad .json files count as skipped.
      expect(result.skipped, 2);
    });

    test('sorts newest first by added_at', () async {
      await store
          .save(validProduct('1', 'Old', addedAt: '2026-08-01T10:00:00Z'));
      await store
          .save(validProduct('2', 'New', addedAt: '2026-08-17T10:00:00Z'));
      await store
          .save(validProduct('3', 'Mid', addedAt: '2026-08-10T10:00:00Z'));

      final result = await store.listAll();
      expect(result.products.map((p) => p.barcode), ['2', '3', '1']);
    });
  });

  group('load', () {
    test('missing id → null', () async {
      expect(await store.load('nope'), isNull);
    });

    test('corrupt file → null, never throws (§7)', () async {
      await File('${root.path}/corrupt.json').writeAsString('{not json');
      expect(await store.load('corrupt'), isNull);
    });

    test('round-trips a saved product, sparse nutriments intact', () async {
      final saved = await store.save(validProduct('222', 'Skyr',
          addedAt: '2026-08-17T10:00:00Z',
          nutriments: const Nutriments(kcal: 63, protein: 11)));
      final loaded = await store.load('222');
      expect(loaded!.toJson(), saved.toJson());
      expect(loaded.nutriments!.kcal, 63.0);
      expect(loaded.nutriments!.protein, 11.0);
      expect(loaded.nutriments!.fat, isNull); // missing stays missing
    });

    test('manual product loads by its slug id', () async {
      await store.save(validProduct('', 'Plain Flour'));
      final loaded = await store.load('plain-flour');
      expect(loaded!.name, 'Plain Flour');
      expect(loaded.source, 'manual');
    });
  });

  group('save', () {
    test('blocking problems → StateError, no file written', () async {
      await expectLater(
          store.save(validProduct('bad', '')), throwsStateError);
      expect(await File('${root.path}/bad.json').exists(), isFalse);
    });

    test('writes <barcode>.json with indented JSON', () async {
      await store.save(
          validProduct('333', 'Butter', addedAt: '2026-08-17T10:00:00Z'));
      final onDisk =
          jsonDecode(await File('${root.path}/333.json').readAsString())
              as Map<String, dynamic>;
      expect(onDisk['barcode'], '333');
      expect(onDisk['name'], 'Butter');
      expect(onDisk['source'], 'off');
    });

    test('same barcode twice = update, not duplicate', () async {
      await store.save(
          validProduct('444', 'Mislabeled', addedAt: '2026-08-17T10:00:00Z'));
      await store.save(
          validProduct('444', 'Corrected', addedAt: '2026-08-17T11:00:00Z'));

      final result = await store.listAll();
      expect(result.products, hasLength(1));
      expect(result.products.single.name, 'Corrected');
      final files = await root
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .length;
      expect(files, 1);
    });

    test('same manual name twice = one slug file, not duplicate', () async {
      await store.save(validProduct('', 'Brown Sugar'));
      await store.save(validProduct('', 'Brown  sugar!')); // same slug
      final result = await store.listAll();
      expect(result.products, hasLength(1));
      expect(result.products.single.id, 'brown-sugar');
    });
  });

  group('update', () {
    test('rewrites the product in place', () async {
      final saved = await store.save(validProduct('555', 'Yoghurt',
          addedAt: '2026-08-17T10:00:00Z',
          nutriments: const Nutriments(kcal: 60)));

      final updated = await store.update(saved.copyWith(
          name: 'Greek Yoghurt',
          nutriments: const Nutriments(kcal: 97, protein: 9)));

      expect(updated.id, '555');
      final loaded = await store.load('555');
      expect(loaded!.name, 'Greek Yoghurt');
      expect(loaded.nutriments!.kcal, 97.0);
      expect(loaded.nutriments!.protein, 9.0);
      expect((await store.listAll()).products, hasLength(1));
    });

    test('unknown product → StateError, nothing written', () async {
      await expectLater(
          store.update(validProduct('666', 'Ghost')), throwsStateError);
      expect(await File('${root.path}/666.json').exists(), isFalse);
    });
  });

  group('delete', () {
    test('removes the JSON, leaves other products alone', () async {
      await store.save(
          validProduct('777', 'Doomed', addedAt: '2026-08-17T10:00:00Z'));
      await store.save(
          validProduct('888', 'Keeper', addedAt: '2026-08-16T10:00:00Z'));

      await store.delete('777');

      expect(await File('${root.path}/777.json').exists(), isFalse);
      expect(await File('${root.path}/888.json').exists(), isTrue);
      expect((await store.listAll()).products.map((p) => p.id), ['888']);
    });

    test('unknown id is a no-op', () async {
      await store.delete('never-existed');
      expect(await root.exists(), isTrue);
    });

    test('takes a stranded .tmp shadow with it', () async {
      await store.save(
          validProduct('999', 'Shadowed', addedAt: '2026-08-17T10:00:00Z'));
      await File('${root.path}/999.json.tmp').writeAsString('stranded');
      await store.delete('999');
      expect(await File('${root.path}/999.json').exists(), isFalse);
      expect(await File('${root.path}/999.json.tmp').exists(), isFalse);
    });
  });

  group('confinement (arch §7)', () {
    test('save refuses a traversal barcode', () async {
      await expectLater(
          store.save(validProduct('../escape', 'Hostile')), throwsStateError);
    });

    test('traversal id never escapes root on load/delete', () async {
      final outer = await Directory.systemTemp.createTemp('recibook_outer');
      cleanup.add(outer);
      final confined = LocalPantryStore(Directory('${outer.path}/pantry'));
      final victim = await File('${outer.path}/victim.json').writeAsString('mine');

      await confined.root.create(recursive: true);
      await confined.delete('../victim');
      expect(await victim.exists(), isTrue); // traversal id is a no-op
      expect(await confined.load('../victim'), isNull);
    });
  });
}
