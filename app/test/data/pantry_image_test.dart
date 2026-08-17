// Product photos — the recipe-cover contract applied to the pantry: copy-in,
// jpg↔png replace cleans up the leftover, remove takes the bytes, delete
// takes the photo, and pre-photo files round-trip without an image key.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/product_store.dart';
import 'package:myrecibook/domain/product.dart';

void main() {
  late Directory dir;
  late LocalPantryStore store;

  const milk = Product(
    schemaVersion: 1,
    barcode: '7038010071751',
    name: 'Mellommelk 2,0% fett',
    source: 'off',
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pantry_image_test');
    store = LocalPantryStore(dir);
    await store.save(milk);
  });

  tearDown(() => dir.delete(recursive: true));

  File photo(String name) {
    final f = File('${dir.path}/../${dir.path.split('/').last}_$name')
      ..writeAsBytesSync([1, 2, 3]);
    addTearDown(() => f.delete());
    return f;
  }

  test('attach copies the photo in and saves the ref', () async {
    final updated = await store.attachImage(milk, photo('shot.jpg'));
    expect(updated.image, 'images/7038010071751.jpg');
    expect(File('${dir.path}/images/7038010071751.jpg').existsSync(), isTrue);
    expect((await store.load(milk.id))?.image, 'images/7038010071751.jpg');
  });

  test('jpg→png replace cleans up the old extension', () async {
    await store.attachImage(milk, photo('a.jpg'));
    final updated = await store.attachImage(milk, photo('b.png'));
    expect(updated.image, 'images/7038010071751.png');
    expect(File('${dir.path}/images/7038010071751.png').existsSync(), isTrue);
    expect(File('${dir.path}/images/7038010071751.jpg').existsSync(), isFalse);
  });

  test('removeImage takes the bytes and the ref', () async {
    final withImage = await store.attachImage(milk, photo('c.jpg'));
    final cleared = await store.removeImage(withImage);
    expect(cleared.image, isNull);
    expect(File('${dir.path}/images/7038010071751.jpg').existsSync(), isFalse);
    expect((await store.load(milk.id))?.image, isNull);
  });

  test('delete takes the photo with the product', () async {
    await store.attachImage(milk, photo('d.jpg'));
    await store.delete(milk.id);
    expect(File('${dir.path}/images/7038010071751.jpg').existsSync(), isFalse);
  });

  test('imageFile refuses a foreign ref (confinement)', () {
    final hostile = milk.copyWith(image: 'images/../../etc/passwd');
    expect(store.imageFile(hostile), isNull);
    final absolute = milk.copyWith(image: '/etc/passwd');
    expect(store.imageFile(absolute), isNull);
  });

  test('photo-less product round-trips without an image key', () async {
    final json = milk.toJson();
    expect(json.containsKey('image'), isFalse);
    expect(Product.fromJson(json).image, isNull);
  });
}
