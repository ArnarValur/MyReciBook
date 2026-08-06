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
    });
  });
}
