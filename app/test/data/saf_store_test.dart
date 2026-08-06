// SafFolderStore against the in-memory SAF fake — mirrors the LocalFolderStore
// contract tests (hostile folder §7, layout, confinement) plus the SAF-only
// behaviours: overwrite never auto-renames, hydrate-to-cache, GrantLost.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/app_settings.dart';
import 'package:myrecibook/data/migration.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/saf_store.dart';
import 'package:myrecibook/domain/recipe.dart';

import 'fake_saf_channel.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSafChannel fake;
  late Directory cache;
  late SafFolderStore store;
  final cleanup = <Directory>[];

  setUp(() async {
    fake = FakeSafChannel()..install();
    cache = await Directory.systemTemp.createTemp('recibook_saf_cache');
    cleanup.add(cache);
    store = SafFolderStore(
        treeUri: fake.treeUri, imageCache: cache, channel: fake.channel);
  });

  tearDown(() async {
    fake.uninstall();
    for (final dir in cleanup) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    cleanup.clear();
  });

  Future<File> tempImage(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('recibook_saf_img');
    cleanup.add(dir);
    return File('${dir.path}/$name').writeAsBytes(bytes);
  }

  Map<String, dynamic> jsonDoc(String name) =>
      jsonDecode(utf8.decode(fake.find(name)!.bytes)) as Map<String, dynamic>;

  group('listAll', () {
    test('empty tree → empty, zero skipped', () async {
      final result = await store.listAll();
      expect(result.recipes, isEmpty);
      expect(result.skipped, 0);
    });

    test('hostile folder: foreign and corrupt files skipped, valid load',
        () async {
      await store.save(
          validRecipe('good-1', importedAt: '2026-08-01T10:00:00Z'), const []);
      fake.seedFile('shopping.txt', utf8.encode('not a recipe'));
      fake.seedFile('broken.json', utf8.encode('{not json at all'));
      fake.seedFile('foreign.json', utf8.encode(jsonEncode({'some': 'other app'})));

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['good-1']);
      // .txt is ignored outright; the two bad .json files count as skipped.
      expect(result.skipped, 2);
    });

    test('unreadable child counts skipped, never fatal', () async {
      await store.save(
          validRecipe('good-1', importedAt: '2026-08-01T10:00:00Z'), const []);
      // A directory named like a JSON file: readFile on it throws SAF_IO.
      fake.seedDir('trap.json');

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['good-1']);
      expect(result.skipped, 0); // dirs are not files — not even counted
    });

    test('sorts newest first by imported_at', () async {
      await store.save(
          validRecipe('old', importedAt: '2026-08-01T10:00:00Z'), const []);
      await store.save(
          validRecipe('new', importedAt: '2026-08-06T10:00:00Z'), const []);
      await store.save(
          validRecipe('mid', importedAt: '2026-08-03T10:00:00Z'), const []);

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['new', 'mid', 'old']);
    });
  });

  group('load', () {
    test('missing id → null', () async {
      expect(await store.load('nope'), isNull);
    });

    test('corrupt file → null, never throws (§7)', () async {
      fake.seedFile('corrupt.json', utf8.encode('{not json'));
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
    test('blocking problems → StateError, nothing written', () async {
      final invalid = validRecipe('bad').copyWith(title: '');
      await expectLater(store.save(invalid, const []), throwsStateError);
      expect(fake.find('bad.json'), isNull);
    });

    test('copies images in order and rewrites original_images', () async {
      final img1 = await tempImage('shot_a.jpg', [1, 2, 3]);
      final img2 = await tempImage('shot_b.PNG', [4, 5, 6]);

      final saved = await store.save(
          validRecipe('r2', importedAt: '2026-08-06T10:00:00Z'), [img1, img2]);

      expect(saved.source.originalImages, ['images/r2-1.jpg', 'images/r2-2.png']);
      final imagesDirId = fake.findId('images')!;
      expect(fake.find('r2-1.jpg', parentId: imagesDirId)!.bytes, [1, 2, 3]);
      expect(fake.find('r2-2.png', parentId: imagesDirId)!.bytes, [4, 5, 6]);

      // The JSON in the tree carries the relative paths and 2-space indent.
      expect((jsonDoc('r2.json')['source'] as Map)['original_images'],
          ['images/r2-1.jpg', 'images/r2-2.png']);
      expect(utf8.decode(fake.find('r2.json')!.bytes),
          const JsonEncoder.withIndent('  ').convert(saved.toJson()));
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
      expect((jsonDoc('r3.json')['source'] as Map)['original_images'],
          ['images/r3-1.jpg']);
    });

    test('overwrite reuses the docId — one file, no "(1)" auto-rename',
        () async {
      final img = await tempImage('a.jpg', [1]);
      await store.save(
          validRecipe('r4', importedAt: '2026-08-06T10:00:00Z'), [img]);
      final edited = (await store.load('r4'))!.copyWith(notes: 'less salt');
      await store.save(edited, const []);
      final img2 = await tempImage('b.jpg', [7]);
      await store.save(
          validRecipe('r4', importedAt: '2026-08-06T10:00:00Z'), [img2]);

      final rootNames = [for (final d in fake.childrenOf(FakeSafChannel.rootId)) d.name];
      expect(rootNames.where((n) => n.startsWith('r4')), ['r4.json']);
      final imagesDirId = fake.findId('images')!;
      final imgNames = [for (final d in fake.childrenOf(imagesDirId)) d.name];
      expect(imgNames, ['r4-1.jpg']);
      expect(fake.find('r4-1.jpg', parentId: imagesDirId)!.bytes, [7]);
    });

    test('fake itself auto-renames raw collisions (contract fidelity)',
        () async {
      // Proves the store's map-first guard is what prevents "(1)" files.
      final ch = fake.channel;
      final id1 = await ch.invokeMethod<String>('createFile', {
        'treeUri': fake.treeUri,
        'parentDocId': FakeSafChannel.rootId,
        'name': 'dup.json',
        'mime': 'application/json',
      });
      final id2 = await ch.invokeMethod<String>('createFile', {
        'treeUri': fake.treeUri,
        'parentDocId': FakeSafChannel.rootId,
        'name': 'dup.json',
        'mime': 'application/json',
      });
      expect(id1, isNot(id2));
      expect(fake.docs[id2]!.name, 'dup (1).json');
    });

    test('"no steps" recipe saves (non-blocking, D4/D5 retake flow)', () async {
      final saved = await store.save(
          validRecipe('r5', importedAt: '2026-08-06T10:00:00Z', steps: []),
          const []);
      expect(saved.steps, isEmpty);
      expect((await store.listAll()).recipes.map((r) => r.id), contains('r5'));
    });

    test('save refuses a traversal id', () async {
      await expectLater(
          store.save(validRecipe('../escape'), const []), throwsStateError);
    });
  });

  group('imageFile', () {
    test('hydrates to cache once, then serves the cached file', () async {
      final img = await tempImage('a.jpg', [9, 8, 7]);
      await store.save(
          validRecipe('r6', importedAt: '2026-08-06T10:00:00Z'), [img]);

      final readsBefore = fake.reads;
      final first = await store.imageFile('images/r6-1.jpg');
      expect(await first!.readAsBytes(), [9, 8, 7]);
      expect(first.path, startsWith(cache.path));
      expect(fake.reads, readsBefore + 1);

      final second = await store.imageFile('images/r6-1.jpg');
      expect(second!.path, first.path);
      expect(fake.reads, readsBefore + 1); // cache hit — no second SAF read
    });

    test('unsafe refs → null; absolute paths pass through', () async {
      expect(await store.imageFile('images/../escape.jpg'), isNull);
      expect(await store.imageFile('images/missing.jpg'), isNull);
      expect((await store.imageFile('/abs/pre-save.jpg'))!.path,
          '/abs/pre-save.jpg');
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

      expect(fake.find('doomed.json'), isNull);
      final imagesDirId = fake.findId('images')!;
      expect(fake.find('doomed-1.jpg', parentId: imagesDirId), isNull);
      expect(fake.find('keeper.json'), isNotNull);
      expect(fake.find('keeper-1.jpg', parentId: imagesDirId), isNotNull);
    });

    test('unknown id is a no-op', () async {
      await store.delete('never-existed');
    });

    test('corrupt JSON still gets deleted', () async {
      fake.seedFile('corrupt.json', utf8.encode('{definitely not json'));
      await store.delete('corrupt');
      expect(fake.find('corrupt.json'), isNull);
    });

    test('images/ gone mid-session: JSON + hydrated copy still removed (§7)',
        () async {
      final img = await tempImage('a.jpg', [1, 2]);
      await store.save(
          validRecipe('r9', importedAt: '2026-08-06T10:00:00Z'), [img]);
      await store.imageFile('images/r9-1.jpg'); // hydrate the cache copy
      await store.listAll(); // fresh root scan → images/ listed lazily again
      // User deletes images/ in the Files app: the held dir id goes stale.
      fake.docs.remove(fake.findId('images'));

      await store.delete('r9'); // must not throw

      expect(fake.find('r9.json'), isNull);
      expect(await File('${cache.path}/r9-1.jpg').exists(), isFalse);
    });

    test('hostile original_images and traversal ids never escape (§7)',
        () async {
      final hostile = validRecipe('hostile', importedAt: '2026-08-06T10:00:00Z')
          .toJson()
        ..['source'] = {
          'type': 'screenshot',
          'imported_at': '2026-08-06T10:00:00Z',
          'original_images': ['../victim.jpg'],
          'app_hint': null,
        };
      fake.seedFile('hostile.json', utf8.encode(jsonEncode(hostile)));
      final victimId = fake.seedFile('victim.jpg', [9]);

      await store.delete('hostile');
      expect(fake.docs[victimId], isNotNull); // traversal image skipped
      expect(fake.find('hostile.json'), isNull); // its own JSON still goes

      await store.delete('../victim');
      expect(fake.docs[victimId], isNotNull); // traversal id is a no-op
      expect(await store.load('../victim'), isNull);
    });
  });

  group('grant lost', () {
    test('listAll surfaces GrantLostException, not a crash', () async {
      await store.save(
          validRecipe('r7', importedAt: '2026-08-06T10:00:00Z'), const []);
      fake.revoked = true;
      await expectLater(
          store.listAll(), throwsA(isA<GrantLostException>()));
    });

    test('save surfaces GrantLostException', () async {
      fake.revoked = true;
      await expectLater(
          store.save(validRecipe('r8', importedAt: '2026-08-06T10:00:00Z'),
              const []),
          throwsA(isA<GrantLostException>()));
    });
  });

  group('migration', () {
    test('moves recipes + images, sets the flag, idempotent via the flag',
        () async {
      final localRoot =
          await Directory.systemTemp.createTemp('recibook_migr_local');
      cleanup.add(localRoot);
      final local = LocalFolderStore(localRoot);
      final img = await tempImage('a.jpg', [5, 5, 5]);
      await local.save(
          validRecipe('m1', importedAt: '2026-08-06T10:00:00Z'), [img]);
      await local.save(
          validRecipe('m2', importedAt: '2026-08-05T10:00:00Z'), const []);
      // Corrupt local file stays behind silently.
      await File('${localRoot.path}/broken.json').writeAsString('{nope');

      final settingsDir =
          await Directory.systemTemp.createTemp('recibook_migr_cfg');
      cleanup.add(settingsDir);
      final settings =
          await AppSettings.load(File('${settingsDir.path}/settings.json'));

      final moved = await migrateLocalToSaf(local, store, settings: settings);
      expect(moved, 2);
      expect(settings.migrationDone, isTrue);

      final result = await store.listAll();
      expect(result.recipes.map((r) => r.id), ['m1', 'm2']);
      expect(await (await store.imageFile('images/m1-1.jpg'))!.readAsBytes(),
          [5, 5, 5]);
      // Originals left in place (cheap insurance, alpha).
      expect(await File('${localRoot.path}/m1.json').exists(), isTrue);

      // Flag makes a second run a no-op — no duplicates, count 0.
      final again = await migrateLocalToSaf(local, store, settings: settings);
      expect(again, 0);
      final names = [
        for (final d in fake.childrenOf(FakeSafChannel.rootId))
          if (d.name.endsWith('.json')) d.name
      ];
      expect(names.length, 2);
    });

    test('transient SAF_IO leaves the flag unset; next run finishes the job',
        () async {
      final localRoot =
          await Directory.systemTemp.createTemp('recibook_migr_local');
      cleanup.add(localRoot);
      final local = LocalFolderStore(localRoot);
      await local.save(
          validRecipe('m1', importedAt: '2026-08-06T10:00:00Z'), const []);
      await local.save(
          validRecipe('m2', importedAt: '2026-08-05T10:00:00Z'), const []);

      final settingsDir =
          await Directory.systemTemp.createTemp('recibook_migr_cfg');
      cleanup.add(settingsDir);
      final settings =
          await AppSettings.load(File('${settingsDir.path}/settings.json'));

      fake.failWrites = 1; // m1's JSON write hiccups (provider blip)
      final moved = await migrateLocalToSaf(local, store, settings: settings);
      expect(moved, 1);
      expect(settings.migrationDone, isFalse); // m1 must get another chance

      final again = await migrateLocalToSaf(local, store, settings: settings);
      expect(again, 2); // idempotent overwrite — m1 recovered, no dupes
      expect(settings.migrationDone, isTrue);
      final names = [
        for (final d in fake.childrenOf(FakeSafChannel.rootId))
          if (d.name.endsWith('.json')) d.name
      ];
      expect(names..sort(), ['m1.json', 'm2.json']);
    });
  });
}
