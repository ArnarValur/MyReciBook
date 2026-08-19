// SyncSource impls. SafFolderSource against the fake SAF bridge: layout
// listing, byte round-trips, the map-first no-auto-rename write discipline,
// GRANT_LOST → GrantLostException. LocalFolderSource: same layout over
// dart:io. Both: name confinement (§7) — nothing outside root/images.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/remote_store.dart' show SyncIoException;
import 'package:myrecibook/data/saf_store.dart' show GrantLostException;
import 'package:myrecibook/data/sync_source.dart';

import 'fake_saf_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('safeName', () {
    test('admits exactly the five layout shapes', () {
      expect(SyncSource.safeName('a.json'), isTrue);
      expect(SyncSource.safeName('notes.txt'), isTrue); // any root segment
      expect(SyncSource.safeName('images/a-1.jpg'), isTrue);
      expect(SyncSource.safeName('pantry/7038010071751.json'), isTrue);
      expect(SyncSource.safeName('pantry/plain-flour.json'), isTrue);
      expect(SyncSource.safeName('pantry/images/7038010071751.jpg'), isTrue);
      expect(SyncSource.safeName('diary/2026-08-19.json'), isTrue);
    });

    test('refuses everything outside them', () {
      expect(SyncSource.safeName('../x.json'), isFalse);
      expect(SyncSource.safeName('images/../x'), isFalse);
      expect(SyncSource.safeName('pantry/..'), isFalse);
      expect(SyncSource.safeName('pantry/../x.json'), isFalse);
      expect(SyncSource.safeName('pantry/images/../x.jpg'), isFalse);
      expect(SyncSource.safeName('pantry/a/b.json'), isFalse); // deeper nesting
      expect(SyncSource.safeName('pantry/images/a/b.jpg'), isFalse);
      expect(SyncSource.safeName('pantry/notes.txt'), isFalse); // json only
      expect(SyncSource.safeName('pantry/x.json.tmp'), isFalse);
      expect(SyncSource.safeName('pantry/'), isFalse);
      expect(SyncSource.safeName('pantry/images'), isFalse); // dir aliasing
      expect(SyncSource.safeName(r'pantry/a\b.json'), isFalse);
      expect(SyncSource.safeName('meals/1.json'), isFalse); // unknown dir
      expect(SyncSource.safeName('diary/x/y.json'), isFalse); // deeper nesting
      expect(SyncSource.safeName('diary/notes.txt'), isFalse); // json only
      expect(SyncSource.safeName('diary/../x.json'), isFalse);
      expect(SyncSource.safeName('diary/'), isFalse);
      expect(SyncSource.safeName('diary/images/x.jpg'), isFalse); // no images
    });
  });

  group('SafFolderSource', () {
    late FakeSafChannel fake;

    setUp(() {
      fake = FakeSafChannel()..install();
    });
    tearDown(() {
      fake.uninstall();
    });

    SafFolderSource source() =>
        SafFolderSource(treeUri: fake.treeUri, channel: fake.channel);

    test('list maps root + images to relative names, size unknown (-1)',
        () async {
      fake.seedFile('a.json', utf8.encode('{"a":1}'));
      final img = fake.seedDir('images');
      fake.seedFile('a-1.jpg', [1, 2, 3], parentId: img);
      final foreign = fake.seedDir('other');
      fake.seedFile('deep.txt', [9], parentId: foreign); // not our layout

      final listed = await source().list();
      expect(listed.keys.toSet(), {'a.json', 'images/a-1.jpg'});
      expect(listed['a.json']!.size, -1);
    });

    test('read round-trips bytes for root and images files', () async {
      fake.seedFile('a.json', utf8.encode('kjöt ½')); // rule 7 payload
      final img = fake.seedDir('images');
      fake.seedFile('a-1.jpg', [255, 216, 0], parentId: img);

      final src = source();
      expect(await src.read('a.json'), utf8.encode('kjöt ½'));
      expect(await src.read('images/a-1.jpg'), [255, 216, 0]);
    });

    test('read of a name not in the folder → SyncIoException', () async {
      await expectLater(
          source().read('missing.json'), throwsA(isA<SyncIoException>()));
    });

    test('write to an existing name reuses the docId — never "x (1)"',
        () async {
      fake.seedFile('a.json', utf8.encode('old'));
      final src = source(); // no explicit list(): index built lazily
      await src.write('a.json', utf8.encode('new'));

      expect(fake.docs.length, 2); // root + the one file, nothing created
      expect(fake.find('a.json')!.bytes, utf8.encode('new'));
      expect(fake.findId('a (1).json'), isNull);
    });

    test('write creates images/ once, then reuses dir and docIds', () async {
      final src = source();
      await src.write('images/n-1.jpg', [1]);
      await src.write('images/n-1.jpg', [2]);
      await src.write('images/n-2.jpg', [3]);

      final imagesId = fake.findId('images')!;
      expect(fake.docs[imagesId]!.isDir, isTrue);
      final children = fake.childrenOf(imagesId).toList();
      expect({for (final c in children) c.name}, {'n-1.jpg', 'n-2.jpg'});
      expect(fake.find('n-1.jpg', parentId: imagesId)!.bytes, [2]);
    });

    test('write to the root creates the file with the exact name', () async {
      await source().write('b.json', utf8.encode('{}'));
      final doc = fake.find('b.json')!;
      expect(doc.isDir, isFalse);
      expect(doc.bytes, utf8.encode('{}'));
    });

    test('GRANT_LOST → GrantLostException on list, read and write', () async {
      fake.seedFile('a.json', utf8.encode('{}'));
      final src = source();
      await src.list(); // build the index while the grant is alive
      fake.revoked = true;
      await expectLater(src.list(), throwsA(isA<GrantLostException>()));
      await expectLater(
          src.read('a.json'), throwsA(isA<GrantLostException>()));
      await expectLater(src.write('a.json', [1]),
          throwsA(isA<GrantLostException>()));
    });

    test('transient SAF_IO on write → SyncIoException', () async {
      fake.seedFile('a.json', utf8.encode('{}'));
      fake.failWrites = 1;
      await expectLater(source().write('a.json', [1]),
          throwsA(isA<SyncIoException>()));
    });

    test('unsafe names are refused before touching the bridge', () async {
      final src = source();
      await expectLater(src.write('../x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('images/../x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(src.write('a/b.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('pantry/../x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('pantry/a/b.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('pantry/notes.txt', [1]), throwsA(isA<ArgumentError>()));
    });

    test('list maps pantry/ and pantry/images/ into the layout', () async {
      fake.seedFile('a.json', utf8.encode('{"a":1}'));
      final pantry = fake.seedDir('pantry');
      fake.seedFile('7038010071751.json', utf8.encode('{"p":1}'),
          parentId: pantry);
      final pantryImages = fake.seedDir('images', parentId: pantry);
      fake.seedFile('7038010071751.jpg', [9, 9], parentId: pantryImages);
      final foreign = fake.seedDir('other', parentId: pantry);
      fake.seedFile('deep.txt', [1], parentId: foreign); // not our layout

      final listed = await source().list();
      expect(listed.keys.toSet(), {
        'a.json',
        'pantry/7038010071751.json',
        'pantry/images/7038010071751.jpg',
      });
    });

    test('pantry read round-trips bytes', () async {
      final pantry = fake.seedDir('pantry');
      fake.seedFile('skyr.json', utf8.encode('{"n":"Skyr"}'), parentId: pantry);
      final pantryImages = fake.seedDir('images', parentId: pantry);
      fake.seedFile('skyr.jpg', [7, 7, 7], parentId: pantryImages);

      final src = source();
      expect(await src.read('pantry/skyr.json'), utf8.encode('{"n":"Skyr"}'));
      expect(await src.read('pantry/images/skyr.jpg'), [7, 7, 7]);
    });

    test('pantry write creates dirs once, reuses docIds — never "x (1)"',
        () async {
      final src = source();
      await src.write('pantry/111.json', utf8.encode('old'));
      await src.write('pantry/111.json', utf8.encode('new'));
      await src.write('pantry/images/111.jpg', [1]);
      await src.write('pantry/images/111.jpg', [2]);

      final pantryId = fake.findId('pantry')!;
      expect(fake.docs[pantryId]!.isDir, isTrue);
      expect(fake.find('111.json', parentId: pantryId)!.bytes,
          utf8.encode('new'));
      expect(fake.findId('111 (1).json', parentId: pantryId), isNull);
      final imagesId = fake.findId('images', parentId: pantryId)!;
      expect(fake.docs[imagesId]!.isDir, isTrue);
      expect(fake.find('111.jpg', parentId: imagesId)!.bytes, [2]);
      expect(fake.findId('111 (1).jpg', parentId: imagesId), isNull);
      // pantry/images/ landed INSIDE pantry, never at the tree root.
      expect(fake.findId('pantry (1)'), isNull);
      expect(
          fake.docs.values
              .where((d) => d.isDir && d.name == 'pantry')
              .length,
          1);
    });

    test('pantry write into a seeded tree reuses the existing dirs', () async {
      final pantry = fake.seedDir('pantry');
      fake.seedFile('111.json', utf8.encode('old'), parentId: pantry);

      final src = source();
      await src.write('pantry/111.json', utf8.encode('new'));
      await src.write('pantry/images/111.jpg', [3]);

      expect(fake.find('111.json', parentId: pantry)!.bytes,
          utf8.encode('new'));
      expect(fake.findId('pantry (1)'), isNull);
      final imagesId = fake.findId('images', parentId: pantry)!;
      expect(fake.find('111.jpg', parentId: imagesId)!.bytes, [3]);
    });

    test('list maps diary/ into the layout, skips foreign strays', () async {
      final diary = fake.seedDir('diary');
      fake.seedFile('2026-08-19.json', utf8.encode('{"meals":[1]}'),
          parentId: diary);
      final foreign = fake.seedDir('other', parentId: diary);
      fake.seedFile('deep.txt', [1], parentId: foreign); // not our layout

      final listed = await source().list();
      expect(listed.keys.toSet(), {'diary/2026-08-19.json'});
    });

    test('diary read round-trips bytes', () async {
      final diary = fake.seedDir('diary');
      fake.seedFile('2026-08-19.json', utf8.encode('{"meals":[]}'),
          parentId: diary);
      expect(await source().read('diary/2026-08-19.json'),
          utf8.encode('{"meals":[]}'));
    });

    test('diary write creates the dir once, reuses docIds — never "x (1)"',
        () async {
      final src = source();
      await src.write('diary/2026-08-19.json', utf8.encode('old'));
      await src.write('diary/2026-08-19.json', utf8.encode('new'));

      final diaryId = fake.findId('diary')!;
      expect(fake.docs[diaryId]!.isDir, isTrue);
      expect(fake.find('2026-08-19.json', parentId: diaryId)!.bytes,
          utf8.encode('new'));
      expect(fake.findId('2026-08-19 (1).json', parentId: diaryId), isNull);
      expect(fake.findId('diary (1)'), isNull);
    });

    test('diary write into a seeded tree reuses the existing dir', () async {
      final diary = fake.seedDir('diary');
      fake.seedFile('2026-08-19.json', utf8.encode('old'), parentId: diary);

      await source().write('diary/2026-08-19.json', utf8.encode('new'));
      expect(fake.find('2026-08-19.json', parentId: diary)!.bytes,
          utf8.encode('new'));
      expect(fake.findId('diary (1)'), isNull);
    });
  });

  group('LocalFolderSource', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('local-source-test');
    });
    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    test('list covers root files + images/, skips foreign subdirs', () async {
      await File('${tmp.path}/a.json').writeAsString('{"a":1}');
      await Directory('${tmp.path}/images').create();
      await File('${tmp.path}/images/a-1.jpg').writeAsString('img');
      await Directory('${tmp.path}/other').create();
      await File('${tmp.path}/other/x.txt').writeAsString('no');

      final listed = await LocalFolderSource(tmp).list();
      expect(listed.keys.toSet(), {'a.json', 'images/a-1.jpg'});
      expect(listed['a.json']!.size, 7);
    });

    test('write/read round-trip, images dir created on demand', () async {
      final src = LocalFolderSource(tmp);
      await src.write('images/n-1.jpg', [7, 8]);
      expect(await src.read('images/n-1.jpg'), [7, 8]);
    });

    test('missing folder lists empty; missing file read → SyncIoException',
        () async {
      final src = LocalFolderSource(Directory('${tmp.path}/nope'));
      expect(await src.list(), isEmpty);
      await expectLater(src.read('a.json'), throwsA(isA<SyncIoException>()));
    });

    test('unsafe names are refused', () async {
      final src = LocalFolderSource(tmp);
      await expectLater(src.read('../etc'), throwsA(isA<ArgumentError>()));
      await expectLater(src.write('a/b.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write(r'..\x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('pantry/../x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('pantry/notes.txt', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('diary/../x.json', [1]), throwsA(isA<ArgumentError>()));
      await expectLater(
          src.write('diary/notes.txt', [1]), throwsA(isA<ArgumentError>()));
    });

    test('list covers pantry/ + pantry/images/, skips strays and .tmp',
        () async {
      await File('${tmp.path}/a.json').writeAsString('{"a":1}');
      await Directory('${tmp.path}/pantry/images').create(recursive: true);
      await File('${tmp.path}/pantry/111.json').writeAsString('{"p":1}');
      await File('${tmp.path}/pantry/111.json.tmp').writeAsString('partial');
      await File('${tmp.path}/pantry/images/111.jpg').writeAsString('img');
      await Directory('${tmp.path}/pantry/other').create();
      await File('${tmp.path}/pantry/other/x.txt').writeAsString('no');

      final listed = await LocalFolderSource(tmp).list();
      expect(listed.keys.toSet(),
          {'a.json', 'pantry/111.json', 'pantry/images/111.jpg'});
    });

    test('pantry write/read round-trip, dirs created on demand', () async {
      final src = LocalFolderSource(tmp);
      await src.write('pantry/111.json', utf8.encode('{"p":1}'));
      await src.write('pantry/images/111.jpg', [4, 5]);
      expect(await src.read('pantry/111.json'), utf8.encode('{"p":1}'));
      expect(await src.read('pantry/images/111.jpg'), [4, 5]);
      expect(await File('${tmp.path}/pantry/images/111.jpg').exists(), isTrue);
    });

    test('list covers diary/, skips strays and .tmp', () async {
      await Directory('${tmp.path}/diary').create();
      await File('${tmp.path}/diary/2026-08-19.json').writeAsString('{"d":1}');
      await File('${tmp.path}/diary/2026-08-19.json.tmp')
          .writeAsString('partial');
      await Directory('${tmp.path}/diary/other').create();
      await File('${tmp.path}/diary/other/x.txt').writeAsString('no');

      final listed = await LocalFolderSource(tmp).list();
      expect(listed.keys.toSet(), {'diary/2026-08-19.json'});
    });

    test('diary write/read round-trip, dir created on demand', () async {
      final src = LocalFolderSource(tmp);
      await src.write('diary/2026-08-19.json', utf8.encode('{"meals":[]}'));
      expect(await src.read('diary/2026-08-19.json'),
          utf8.encode('{"meals":[]}'));
      expect(
          await File('${tmp.path}/diary/2026-08-19.json').exists(), isTrue);
    });
  });
}
