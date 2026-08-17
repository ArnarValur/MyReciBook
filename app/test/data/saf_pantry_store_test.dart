// SafPantryStore against the fake SAF bridge: the LocalPantryStore contract
// (upsert by stem, §7 hostile-folder skips, photo lifecycle) plus the SAF
// disciplines from saf_store — docId reuse over createFile (never 'x (1)'),
// GRANT_LOST → GrantLostException, SAF_IO → StoreIoException — and the
// hydration cache that keeps ProductStore.imageFile synchronous.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/saf_pantry_store.dart';
import 'package:myrecibook/data/saf_store.dart'
    show GrantLostException, StoreIoException;
import 'package:myrecibook/domain/product.dart';

import 'fake_saf_channel.dart';

Product validProduct(String barcode, String name, {String? addedAt}) =>
    Product(
      schemaVersion: 1,
      barcode: barcode,
      name: name,
      source: barcode.isEmpty ? 'manual' : 'off',
      addedAt: addedAt,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSafChannel fake;
  late Directory tmp;
  late Directory cacheDir;
  late SafPantryStore store;

  setUp(() async {
    fake = FakeSafChannel()..install();
    tmp = await Directory.systemTemp.createTemp('saf_pantry_test');
    cacheDir = Directory('${tmp.path}/pantry_images');
    store = SafPantryStore(
        treeUri: fake.treeUri, imageCache: cacheDir, channel: fake.channel);
  });

  tearDown(() async {
    fake.uninstall();
    await tmp.delete(recursive: true);
  });

  String seedPantryProduct(String id, String name) {
    var pantryId = fake.findId('pantry') ?? fake.seedDir('pantry');
    return fake.seedFile(
        '$id.json',
        utf8.encode(jsonEncode(
            validProduct(id, name, addedAt: '2026-08-17T10:00:00Z').toJson())),
        parentId: pantryId);
  }

  File photo(String name) {
    final f = File('${tmp.path}/$name')..writeAsBytesSync([1, 2, 3]);
    return f;
  }

  test('save writes pantry/<stem>.json inside ONE pantry dir', () async {
    await store.save(validProduct('111', 'Melk', addedAt: '2026-08-17T10:00:00Z'));
    final pantryId = fake.findId('pantry')!;
    expect(fake.docs[pantryId]!.isDir, isTrue);
    final onDisk = jsonDecode(
            utf8.decode(fake.find('111.json', parentId: pantryId)!.bytes))
        as Map<String, dynamic>;
    expect(onDisk['name'], 'Melk');
    // Nothing leaked to the tree root.
    expect(fake.findId('111.json'), isNull);
  });

  test('same stem twice = one file updated in place, never "x (1)"', () async {
    await store.save(validProduct('111', 'Mislabeled',
        addedAt: '2026-08-17T10:00:00Z'));
    await store.save(validProduct('111', 'Corrected',
        addedAt: '2026-08-17T11:00:00Z'));
    final pantryId = fake.findId('pantry')!;
    expect(fake.findId('111 (1).json', parentId: pantryId), isNull);
    expect((await store.listAll()).products.single.name, 'Corrected');
    expect(fake.docs.values.where((d) => d.isDir && d.name == 'pantry').length,
        1);
  });

  test('listAll reads a seeded tree; foreign and corrupt files skipped',
      () async {
    seedPantryProduct('111', 'Melk');
    final pantryId = fake.findId('pantry')!;
    fake.seedFile('broken.json', utf8.encode('{not json'), parentId: pantryId);
    fake.seedFile('foreign.json', utf8.encode('{"some":"app"}'),
        parentId: pantryId);
    fake.seedFile('notes.txt', utf8.encode('no'), parentId: pantryId);

    final result = await store.listAll();
    expect(result.products.map((p) => p.id), ['111']);
    expect(result.skipped, 2); // the two bad .json files; .txt ignored
  });

  test('empty tree lists empty; load of missing/corrupt id → null', () async {
    expect((await store.listAll()).products, isEmpty);
    expect(await store.load('nope'), isNull);
    final pantryId = fake.seedDir('pantry');
    fake.seedFile('corrupt.json', utf8.encode('{not json'), parentId: pantryId);
    expect(await store.load('corrupt'), isNull);
  });

  test('load round-trips a saved product', () async {
    final saved = await store
        .save(validProduct('222', 'Skyr', addedAt: '2026-08-17T10:00:00Z'));
    final loaded = await store.load('222');
    expect(loaded!.toJson(), saved.toJson());
  });

  test('update rewrites in place; unknown product → StateError', () async {
    final saved = await store
        .save(validProduct('555', 'Yoghurt', addedAt: '2026-08-17T10:00:00Z'));
    await store.update(saved.copyWith(name: 'Greek Yoghurt'));
    expect((await store.load('555'))!.name, 'Greek Yoghurt');
    await expectLater(
        store.update(validProduct('666', 'Ghost')), throwsStateError);
    expect(fake.find('666.json', parentId: fake.findId('pantry')!), isNull);
  });

  test('delete removes JSON + photo + cache copy, leaves others', () async {
    await store.save(validProduct('777', 'Doomed',
        addedAt: '2026-08-17T10:00:00Z'));
    await store.attachImage(
        (await store.load('777'))!, photo('doomed.jpg'));
    await store.save(validProduct('888', 'Keeper',
        addedAt: '2026-08-16T10:00:00Z'));

    await store.delete('777');

    final pantryId = fake.findId('pantry')!;
    expect(fake.find('777.json', parentId: pantryId), isNull);
    expect(fake.find('888.json', parentId: pantryId), isNotNull);
    final imagesId = fake.findId('images', parentId: pantryId)!;
    expect(fake.find('777.jpg', parentId: imagesId), isNull);
    expect(File('${cacheDir.path}/777.jpg').existsSync(), isFalse);
  });

  test('confinement: traversal ids never touch the bridge', () async {
    await expectLater(
        store.save(validProduct('../escape', 'Hostile')), throwsStateError);
    expect(await store.load('../victim'), isNull);
    await store.delete('../victim'); // no throw, no effect
    final hostile = validProduct('111', 'X')
        .copyWith(image: 'images/../../etc/passwd');
    expect(store.imageFile(hostile), isNull);
    expect(await store.imageBytes(hostile), isNull);
  });

  group('photos', () {
    const milk = Product(
      schemaVersion: 1,
      barcode: '7038010071751',
      name: 'Mellommelk',
      source: 'off',
    );

    setUp(() => store.save(milk));

    test('attach writes SAF bytes + hydration cache and saves the ref',
        () async {
      final updated = await store.attachImage(milk, photo('shot.jpg'));
      expect(updated.image, 'images/7038010071751.jpg');
      final pantryId = fake.findId('pantry')!;
      final imagesId = fake.findId('images', parentId: pantryId)!;
      expect(fake.find('7038010071751.jpg', parentId: imagesId)!.bytes,
          [1, 2, 3]);
      // pantry/images landed INSIDE pantry, not at the root.
      expect(fake.findId('images'), isNull);
      expect((await store.load(milk.id))?.image, 'images/7038010071751.jpg');
      // Write-through hydration: the sync imageFile sees it immediately.
      expect(store.imageFile(updated)!.readAsBytesSync(), [1, 2, 3]);
    });

    test('jpg→png replace cleans up the old extension everywhere', () async {
      await store.attachImage(milk, photo('a.jpg'));
      final updated = await store.attachImage(milk, photo('b.png'));
      expect(updated.image, 'images/7038010071751.png');
      final pantryId = fake.findId('pantry')!;
      final imagesId = fake.findId('images', parentId: pantryId)!;
      expect(fake.find('7038010071751.jpg', parentId: imagesId), isNull);
      expect(fake.find('7038010071751.png', parentId: imagesId), isNotNull);
      expect(File('${cacheDir.path}/7038010071751.jpg').existsSync(), isFalse);
    });

    test('removeImage takes SAF bytes, cache copy and ref', () async {
      final withImage = await store.attachImage(milk, photo('c.jpg'));
      final cleared = await store.removeImage(withImage);
      expect(cleared.image, isNull);
      final pantryId = fake.findId('pantry')!;
      final imagesId = fake.findId('images', parentId: pantryId)!;
      expect(fake.find('7038010071751.jpg', parentId: imagesId), isNull);
      expect(File('${cacheDir.path}/7038010071751.jpg').existsSync(), isFalse);
      expect((await store.load(milk.id))?.image, isNull);
    });

    test('listAll hydrates a photo that exists only in the tree', () async {
      // Another device synced this photo down: SAF has it, the cache doesn't.
      final pantryId = fake.findId('pantry')!;
      final imagesId = fake.seedDir('images', parentId: pantryId);
      fake.seedFile('7038010071751.jpg', [9, 8, 7], parentId: imagesId);
      final withRef = milk.copyWith(image: 'images/7038010071751.jpg');
      await store.save(withRef);

      final fresh = SafPantryStore(
          treeUri: fake.treeUri, imageCache: cacheDir, channel: fake.channel);
      final result = await fresh.listAll();
      final file = fresh.imageFile(result.products.single)!;
      expect(file.readAsBytesSync(), [9, 8, 7]);
    });
  });

  test('GRANT_LOST → GrantLostException on listAll and save', () async {
    seedPantryProduct('111', 'Melk');
    await store.listAll(); // build the index while the grant is alive
    fake.revoked = true;
    await expectLater(store.listAll(), throwsA(isA<GrantLostException>()));
    await expectLater(
        store.save(validProduct('222', 'X', addedAt: '2026-08-17T10:00:00Z')),
        throwsA(isA<GrantLostException>()));
  });

  test('transient SAF_IO on save → StoreIoException', () async {
    seedPantryProduct('111', 'Melk');
    await store.listAll();
    fake.failWrites = 1;
    await expectLater(
        store.save(validProduct('111', 'Melk', addedAt: '2026-08-17T10:00:00Z')),
        throwsA(isA<StoreIoException>()));
  });
}
