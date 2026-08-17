// docs/pantry → <tree>/pantry/ migration: copy, read-back verify, only then
// delete the old files. The invariants under test: nothing is lost on a
// happy pass OR an interrupted one (old files survive any failure), the pass
// is idempotent (re-run = resume, stems overwrite their own files), and
// foreign/corrupt strays in the old dir are never destroyed (§7).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/migration.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/data/saf_pantry_store.dart';
import 'package:myrecibook/data/saf_store.dart' show GrantLostException;
import 'package:myrecibook/domain/product.dart';

import 'fake_saf_channel.dart';

Product product(String barcode, String name, {String? addedAt, String? image}) =>
    Product(
      schemaVersion: 1,
      barcode: barcode,
      name: name,
      source: 'off',
      addedAt: addedAt,
      image: image,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late Directory oldDir;
  late LocalPantryStore from;
  late FakeSafChannel fake;
  late SafPantryStore to;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('pantry_migration_test');
    oldDir = Directory('${tmp.path}/docs/pantry');
    from = LocalPantryStore(oldDir);
    fake = FakeSafChannel()..install();
    to = SafPantryStore(
        treeUri: fake.treeUri,
        imageCache: Directory('${tmp.path}/cache/pantry_images'),
        channel: fake.channel);
  });

  tearDown(() async {
    fake.uninstall();
    await tmp.delete(recursive: true);
  });

  File scratchPhoto(List<int> bytes) {
    final f = File(
        '${tmp.path}/photo-${DateTime.now().microsecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(bytes);
    return f;
  }

  test('no old dir → no-op, nothing created in the tree', () async {
    expect(await migratePantryToSaf(from, to), 0);
    expect(fake.findId('pantry'), isNull);
  });

  test('happy path: 28 products + photos land verified, old dir removed',
      () async {
    for (var n = 1; n <= 28; n++) {
      final p = await from.save(product('90000000000$n', 'Product $n',
          addedAt: '2026-08-${(n % 28 + 1).toString().padLeft(2, '0')}T10:00:00Z'));
      if (n <= 3) {
        await from.attachImage(p, scratchPhoto([n, n, n]));
      }
    }

    expect(await migratePantryToSaf(from, to), 28);

    // Every product is readable through the SAF store, photos intact.
    final result = await to.listAll();
    expect(result.products, hasLength(28));
    expect(result.skipped, 0);
    for (var n = 1; n <= 3; n++) {
      final p = result.products
          .singleWhere((p) => p.barcode == '90000000000$n');
      expect(p.image, 'images/90000000000$n.jpg');
      expect(await to.imageBytes(p), [n, n, n]);
    }
    // The drained old dir is gone — the migration's own done-flag.
    expect(await oldDir.exists(), isFalse);
    // Re-run is a no-op, not a crash.
    expect(await migratePantryToSaf(from, to), 0);
  });

  test('interrupted pass: failed product keeps its old files, rest drain; '
      'a re-run completes with nothing lost', () async {
    await from.save(
        product('111', 'Newest', addedAt: '2026-08-17T10:00:00Z'));
    final b = await from.save(
        product('222', 'Middle', addedAt: '2026-08-16T10:00:00Z'));
    await from.attachImage(b, scratchPhoto([2, 2, 2]));
    await from.save(
        product('333', 'Oldest', addedAt: '2026-08-15T10:00:00Z'));

    // First SAF write dies (transient SAF_IO) — that's product 111, the
    // newest-first head of the pass.
    fake.failWrites = 1;
    expect(await migratePantryToSaf(from, to), 2);

    // 111 is untouched in the old dir; the others are drained.
    expect(await File('${oldDir.path}/111.json').exists(), isTrue);
    expect(await File('${oldDir.path}/222.json').exists(), isFalse);
    expect(await File('${oldDir.path}/images/222.jpg').exists(), isFalse);
    expect(await File('${oldDir.path}/333.json').exists(), isFalse);
    expect(await oldDir.exists(), isTrue); // not empty → kept

    // Next boot: the leftover migrates, dir drains, nothing was lost.
    expect(await migratePantryToSaf(from, to), 1);
    expect(await oldDir.exists(), isFalse);
    final result = await to.listAll();
    expect(result.products.map((p) => p.barcode).toSet(),
        {'111', '222', '333'});
    expect(await to.imageBytes(result.products
        .singleWhere((p) => p.barcode == '222')), [2, 2, 2]);
  });

  test('resume after a crash between photo-delete and json-delete', () async {
    // Simulated interrupted state: SAF already holds the verified copy
    // (json + photo), the old photo is gone, the old json is not.
    final p = product('444', 'Halfway',
        addedAt: '2026-08-17T10:00:00Z', image: 'images/444.jpg');
    await to.attachImage(p, scratchPhoto([4, 4, 4]));
    await from.save(p); // old json still present, old images/ never existed

    expect(await migratePantryToSaf(from, to), 1);
    expect(await oldDir.exists(), isFalse);
    final back = (await to.listAll()).products.single;
    expect(back.image, 'images/444.jpg');
    expect(await to.imageBytes(back), [4, 4, 4]); // photo survived the resume
  });

  test('foreign and corrupt strays survive; old dir is kept around them',
      () async {
    await from.save(product('555', 'Valid', addedAt: '2026-08-17T10:00:00Z'));
    await oldDir.create(recursive: true);
    await File('${oldDir.path}/notes.txt').writeAsString('user file');
    await File('${oldDir.path}/broken.json').writeAsString('{not json');

    expect(await migratePantryToSaf(from, to), 1);

    expect(await File('${oldDir.path}/555.json').exists(), isFalse);
    expect(await File('${oldDir.path}/notes.txt').readAsString(), 'user file');
    expect(await File('${oldDir.path}/broken.json').exists(), isTrue);
    expect(await oldDir.exists(), isTrue); // never rm -rf'd over strays
    expect(jsonDecode(utf8.decode(fake
            .find('555.json', parentId: fake.findId('pantry')!)!
            .bytes))['name'],
        'Valid');
  });

  test('upsert on resume: a stem already in the tree is overwritten, '
      'not duplicated', () async {
    await to.save(product('666', 'Stale copy', addedAt: '2026-08-01T10:00:00Z'));
    await from.save(product('666', 'Fresh local', addedAt: '2026-08-17T10:00:00Z'));

    expect(await migratePantryToSaf(from, to), 1);
    final pantryId = fake.findId('pantry')!;
    expect(fake.findId('666 (1).json', parentId: pantryId), isNull);
    expect((await to.load('666'))!.name, 'Fresh local');
  });

  test('grant lost mid-pass aborts without touching the old files', () async {
    await from.save(product('777', 'Kept', addedAt: '2026-08-17T10:00:00Z'));
    fake.revoked = true;
    await expectLater(
        migratePantryToSaf(from, to), throwsA(isA<GrantLostException>()));
    expect(await File('${oldDir.path}/777.json').exists(), isTrue);
  });
}
