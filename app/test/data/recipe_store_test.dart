// LocalFolderStore against real temp dirs — hostile-folder behaviour is
// architecture §7: foreign/corrupt files are counted skipped, never fatal.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/recipe.dart';

Recipe validRecipe(String id, {String? importedAt, List<RecipeStep>? steps}) =>
    Recipe(
      schemaVersion: 1,
      id: id,
      title: 'Recipe $id',
      source: RecipeSource(type: 'screenshot', importedAt: importedAt),
      ingredients: const [
        Ingredient(raw: '2 eggs'),
        Ingredient(raw: '250 g flour'),
      ],
      steps: steps ?? const [RecipeStep(raw: 'Mix and fry.')],
    );

void main() {
  late Directory root;
  late LocalFolderStore store;
  final cleanup = <Directory>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('recibook_store_test');
    cleanup.add(root);
    store = LocalFolderStore(root);
  });

  tearDown(() async {
    for (final dir in cleanup) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    cleanup.clear();
  });

  Future<File> tempImage(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('recibook_img_test');
    cleanup.add(dir);
    return File('${dir.path}/$name').writeAsBytes(bytes);
  }

  group('listAll', () {
    test('missing root → empty, zero skipped', () async {
      final result = await LocalFolderStore(
              Directory('${root.path}/does-not-exist'))
          .listAll();
      expect(result.recipes, isEmpty);
      expect(result.skipped, 0);
    });

    test('hostile folder: foreign and corrupt files skipped, valid load',
        () async {
      await store.save(validRecipe('good-1', importedAt: '2026-08-01T10:00:00Z'),
          const []);
      await File('${root.path}/shopping.txt').writeAsString('not a recipe');
      await File('${root.path}/broken.json').writeAsString('{not json at all');
      await File('${root.path}/foreign.json')
          .writeAsString(jsonEncode({'some': 'other app'}));

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['good-1']);
      // .txt is ignored outright; the two bad .json files count as skipped.
      expect(result.skipped, 2);
    });

    test('sorts newest first by imported_at', () async {
      await store.save(validRecipe('old', importedAt: '2026-08-01T10:00:00Z'),
          const []);
      await store.save(validRecipe('new', importedAt: '2026-08-06T10:00:00Z'),
          const []);
      await store.save(validRecipe('mid', importedAt: '2026-08-03T10:00:00Z'),
          const []);

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['new', 'mid', 'old']);
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

    test('round-trips a saved recipe', () async {
      final saved = await store
          .save(validRecipe('r1', importedAt: '2026-08-06T10:00:00Z'), const []);
      final loaded = await store.load('r1');
      expect(loaded!.toJson(), saved.toJson());
    });
  });

  group('save', () {
    test('blocking problems → StateError, no file written', () async {
      final invalid = validRecipe('bad').copyWith(title: '');
      await expectLater(store.save(invalid, const []), throwsStateError);
      expect(await File('${root.path}/bad.json').exists(), isFalse);
    });

    test('copies images in order and rewrites original_images', () async {
      final img1 = await tempImage('shot_a.jpg', [1, 2, 3]);
      final img2 = await tempImage('shot_b.PNG', [4, 5, 6]);

      final saved = await store.save(
          validRecipe('r2', importedAt: '2026-08-06T10:00:00Z'), [img1, img2]);

      expect(saved.source.originalImages,
          ['images/r2-1.jpg', 'images/r2-2.png']);
      expect(await File('${root.path}/images/r2-1.jpg').readAsBytes(),
          [1, 2, 3]);
      expect(await File('${root.path}/images/r2-2.png').readAsBytes(),
          [4, 5, 6]);

      // The JSON on disk carries the relative paths too.
      final onDisk = jsonDecode(
              await File('${root.path}/r2.json').readAsString())
          as Map<String, dynamic>;
      expect((onDisk['source'] as Map)['original_images'],
          ['images/r2-1.jpg', 'images/r2-2.png']);
    });

    test('empty cachedImages preserves existing original_images', () async {
      final base = validRecipe('r3', importedAt: '2026-08-06T10:00:00Z');
      final withImages = Recipe.fromJson(base.toJson()
        ..['source'] = {
          'type': 'screenshot',
          'imported_at': '2026-08-06T10:00:00Z',
          'original_images': ['images/r3-1.jpg'],
          'app_hint': null,
        });

      final saved = await store.save(withImages, const []);
      expect(saved.source.originalImages, ['images/r3-1.jpg']);
      final onDisk = jsonDecode(
              await File('${root.path}/r3.json').readAsString())
          as Map<String, dynamic>;
      expect((onDisk['source'] as Map)['original_images'], ['images/r3-1.jpg']);
    });

    test('"no steps" recipe saves (non-blocking, D4/D5 retake flow)', () async {
      final saved = await store.save(
          validRecipe('r4', importedAt: '2026-08-06T10:00:00Z', steps: []),
          const []);
      expect(saved.steps, isEmpty);
      expect(await File('${root.path}/r4.json').exists(), isTrue);
      expect((await store.listAll()).recipes.map((r) => r.id), contains('r4'));
    });
  });

  group('delete', () {
    test('removes JSON and its images, leaves other recipes alone', () async {
      final img1 = await tempImage('a.jpg', [1]);
      final img2 = await tempImage('b.jpg', [2]);
      await store.save(
          validRecipe('doomed', importedAt: '2026-08-06T10:00:00Z'), [img1]);
      await store.save(
          validRecipe('keeper', importedAt: '2026-08-05T10:00:00Z'), [img2]);

      await store.delete('doomed');

      expect(await File('${root.path}/doomed.json').exists(), isFalse);
      expect(await File('${root.path}/images/doomed-1.jpg').exists(), isFalse);
      expect(await File('${root.path}/keeper.json').exists(), isTrue);
      expect(await File('${root.path}/images/keeper-1.jpg').exists(), isTrue);
    });

    test('unknown id is a no-op', () async {
      await store.delete('never-existed');
      expect(await root.exists(), isTrue);
    });

    test('corrupt JSON still gets deleted', () async {
      final file = File('${root.path}/corrupt.json');
      await file.writeAsString('{definitely not json');
      await store.delete('corrupt');
      expect(await file.exists(), isFalse);
    });

    test('hostile original_images and traversal ids never escape root '
        '(arch §7)', () async {
      final outer = await Directory.systemTemp.createTemp('recibook_outer');
      cleanup.add(outer);
      final confined = LocalFolderStore(Directory('${outer.path}/recipes'));
      final victimImg = await File('${outer.path}/victim.jpg').writeAsBytes([9]);
      final victimJson =
          await File('${outer.path}/victim.json').writeAsString('mine');

      await confined.root.create(recursive: true);
      final hostile = validRecipe('hostile', importedAt: '2026-08-06T10:00:00Z')
          .toJson()
        ..['source'] = {
          'type': 'screenshot',
          'imported_at': '2026-08-06T10:00:00Z',
          'original_images': ['../victim.jpg'],
          'app_hint': null,
        };
      await File('${confined.root.path}/hostile.json')
          .writeAsString(jsonEncode(hostile));

      await confined.delete('hostile');
      expect(await victimImg.exists(), isTrue); // traversal image skipped
      expect(await File('${confined.root.path}/hostile.json').exists(),
          isFalse); // the recipe's own JSON still goes

      await confined.delete('../victim');
      expect(await victimJson.exists(), isTrue); // traversal id is a no-op
      expect(await confined.load('../victim'), isNull);
    });
  });

  group('confinement', () {
    test('save refuses a traversal id', () async {
      await expectLater(
          store.save(validRecipe('../escape'), const []), throwsStateError);
    });
  });
}
