// SyncEngine over a real temp folder + counting FakeRemote: initial mirror,
// hash-based no-op passes, delete propagation with the foreign-file fence,
// crash-resume via the persisted manifest, additive restore, coalesced
// concurrent passes, and the §7 status stances (offline / authRevoked /
// GrantLost propagation). One end-to-end pass runs against the SAF fake.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/remote_store.dart';
import 'package:myrecibook/data/saf_store.dart' show GrantLostException;
import 'package:myrecibook/data/sha256.dart';
import 'package:myrecibook/data/sync_engine.dart';
import 'package:myrecibook/data/sync_source.dart';

import 'fake_saf_channel.dart';

class FakeRemote implements RemoteStore {
  final files = <String, List<int>>{};
  int uploads = 0;
  int deletes = 0;
  int listCalls = 0;
  Object? Function(String name)? failUpload; // non-null return is thrown
  Object? Function(String name)? failDownload;
  Future<void> Function()? uploadGate; // awaited before every upload

  @override
  Future<Map<String, RemoteEntry>> list() async {
    listCalls++;
    return {
      for (final e in files.entries)
        e.key:
            RemoteEntry(name: e.key, size: e.value.length, rev: 'r${e.value.length}'),
    };
  }

  @override
  Future<void> upload(String name, List<int> bytes) async {
    await uploadGate?.call();
    final err = failUpload?.call(name);
    if (err != null) throw err;
    uploads++;
    files[name] = List.of(bytes);
  }

  @override
  Future<List<int>> download(String name) async {
    final err = failDownload?.call(name);
    if (err != null) throw err;
    final bytes = files[name];
    if (bytes == null) throw SyncIoException('missing $name');
    return bytes;
  }

  @override
  Future<void> delete(String name) async {
    deletes++;
    files.remove(name);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const idA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const idB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const jsonA = '$idA.json';
  const jsonB = '$idB.json';
  const img = 'images/$idA-1.jpg';

  late Directory tmp;
  late Directory folder;
  late FakeRemote remote;
  late File manifestFile;
  late List<SyncStatus> statuses;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('sync-engine-test');
    folder = Directory('${tmp.path}/folder');
    await folder.create();
    remote = FakeRemote();
    manifestFile = File('${tmp.path}/private/manifest.json');
    statuses = [];
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  SyncEngine engine() => SyncEngine(
        source: LocalFolderSource(folder),
        remote: remote,
        manifestFile: manifestFile,
        onStatus: statuses.add,
      );

  Future<void> put(String rel, String content) async {
    final f = File('${folder.path}/$rel');
    await f.parent.create(recursive: true);
    await f.writeAsString(content);
  }

  test('initial pass mirrors everything up and persists the manifest',
      () async {
    await put(jsonA, '{"a":1}');
    await put(jsonB, '{"b":2}');
    await put(img, 'jpeg-bytes');

    final e = engine();
    await e.syncUp();

    expect(remote.uploads, 3);
    expect(remote.files.keys.toSet(), {jsonA, jsonB, img});
    expect(utf8.decode(remote.files[jsonA]!), '{"a":1}');
    expect([for (final s in statuses) s.state],
        [SyncState.syncing, SyncState.synced]);
    expect(e.status.syncedAt, isNotNull);
    final manifest =
        jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    expect((manifest['files'] as Map).keys.toSet(), {jsonA, jsonB, img});
  });

  test('unchanged folder → zero uploads on the next pass', () async {
    await put(jsonA, '{"a":1}');
    await put(img, 'jpeg-bytes');
    final e = engine();
    await e.syncUp();
    expect(remote.uploads, 2);

    await e.syncUp();
    expect(remote.uploads, 2); // hash matched — nothing re-sent
    expect(e.status.state, SyncState.synced);
  });

  test('changed file re-uploads, only that file', () async {
    await put(jsonA, '{"a":1}');
    await put(jsonB, '{"b":2}');
    final e = engine();
    await e.syncUp();

    await put(jsonA, '{"a":"edited"}');
    await e.syncUp();
    expect(remote.uploads, 3);
    expect(utf8.decode(remote.files[jsonA]!), '{"a":"edited"}');
    expect(utf8.decode(remote.files[jsonB]!), '{"b":2}');
  });

  test('source-deleted recipe deletes remote; foreign remote file untouched',
      () async {
    await put(jsonA, '{"a":1}');
    remote.files['foreign-notes.txt'] = utf8.encode('not ours');
    final e = engine();
    await e.syncUp();

    await File('${folder.path}/$jsonA').delete();
    await e.syncUp();
    expect(remote.deletes, 1);
    expect(remote.files.containsKey(jsonA), isFalse);
    expect(remote.files.containsKey('foreign-notes.txt'), isTrue);
  });

  test('tracked non-layout name is dropped from tracking, never deleted remotely',
      () async {
    await put('notes.txt', 'user file'); // mirrored up, but not uuid.json
    final e = engine();
    await e.syncUp();
    expect(remote.files.containsKey('notes.txt'), isTrue);

    await File('${folder.path}/notes.txt').delete();
    await e.syncUp();
    expect(remote.deletes, 0); // fence held
    expect(remote.files.containsKey('notes.txt'), isTrue);
  });

  test('crash mid-pass: manifest keeps what landed, a NEW engine resumes',
      () async {
    await put(jsonA, '{"a":1}');
    await put(jsonB, '{"b":2}');
    await put(img, 'jpeg-bytes');
    // Sorted order is jsonA, jsonB, img — fail the second upload.
    remote.failUpload =
        (name) => name == jsonB ? SyncIoException('link dropped') : null;

    final e1 = engine();
    await e1.syncUp(); // must complete, not throw
    expect(e1.status.state, SyncState.offline);
    expect(remote.uploads, 1);

    remote.failUpload = null;
    final e2 = engine(); // fresh instance = fresh process, manifest from disk
    await e2.syncUp();
    expect(remote.uploads, 3); // jsonA was NOT re-uploaded
    expect(remote.files.keys.toSet(), {jsonA, jsonB, img});
    expect(e2.status.state, SyncState.synced);
  });

  test('corrupt manifest → starts clean, re-uploads, never crashes', () async {
    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString('{"files": [not json');
    await put(jsonA, '{"a":1}');
    final e = engine();
    await e.syncUp();
    expect(remote.uploads, 1);
    expect(e.status.state, SyncState.synced);
  });

  test('restoreDown is additive and never overwrites', () async {
    remote.files[jsonA] = utf8.encode('{"a":"remote"}');
    remote.files[img] = utf8.encode('jpeg-bytes');
    await put(jsonA, '{"a":"local"}');

    final e = engine();
    final restored = await e.restoreDown();
    expect(restored, 1); // only the image was missing locally
    expect(await File('${folder.path}/$jsonA').readAsString(),
        '{"a":"local"}'); // untouched
    expect(await File('${folder.path}/$img').readAsString(), 'jpeg-bytes');

    // The restored file is recorded as landed: the next pass only pushes the
    // genuinely divergent json, not the image we just pulled.
    await e.syncUp();
    expect(remote.uploads, 1);
    expect(utf8.decode(remote.files[jsonA]!), '{"a":"local"}');
  });

  test('restoreDown skips hostile remote names', () async {
    remote.files['../evil.json'] = utf8.encode('{}');
    remote.files['images/../also-evil.json'] = utf8.encode('{}');
    remote.files[jsonA] = utf8.encode('{"a":1}');

    final restored = await engine().restoreDown();
    expect(restored, 1);
    expect(await File('${tmp.path}/evil.json').exists(), isFalse);
    expect(await File('${folder.path}/also-evil.json').exists(), isFalse);
  });

  test('restoreDown failure throws typed and reports offline', () async {
    remote.files[jsonA] = utf8.encode('{"a":1}');
    remote.failDownload = (_) => SyncIoException('flaky');
    final e = engine();
    await expectLater(e.restoreDown(), throwsA(isA<SyncIoException>()));
    expect(e.status.state, SyncState.offline);
  });

  test('concurrent syncUp calls coalesce into one pass', () async {
    await put(jsonA, '{"a":1}');
    await put(jsonB, '{"b":2}');
    final gate = Completer<void>();
    remote.uploadGate = () => gate.future;

    final e = engine();
    final f1 = e.syncUp();
    final f2 = e.syncUp();
    expect(identical(f1, f2), isTrue); // joined, not queued twice
    gate.complete();
    await f1;
    await f2;
    expect(remote.uploads, 2); // one pass, no double-upload

    remote.uploadGate = null;
    await e.syncUp(); // after completion a fresh pass is allowed again
    expect(remote.uploads, 2); // and it is a no-op
  });

  test('AuthRevokedException → authRevoked status, no throw', () async {
    await put(jsonA, '{"a":1}');
    remote.failUpload = (_) => const AuthRevokedException('user revoked');
    final e = engine();
    await e.syncUp();
    expect(e.status.state, SyncState.authRevoked);
  });

  test('offline pass keeps manifest intact and resumes next time', () async {
    await put(jsonA, '{"a":1}');
    remote.failUpload = (_) => SyncIoException('no network');
    final e = engine();
    await e.syncUp();
    expect(e.status.state, SyncState.offline);
    expect(remote.uploads, 0);

    remote.failUpload = null;
    await e.syncUp();
    expect(remote.uploads, 1);
    expect(e.status.state, SyncState.synced);
  });

  test('GrantLostException propagates out of syncUp (re-pick flow owns it)',
      () async {
    final fake = FakeSafChannel()..install();
    addTearDown(fake.uninstall);
    fake.revoked = true;
    final e = SyncEngine(
      source: SafFolderSource(treeUri: fake.treeUri, channel: fake.channel),
      remote: remote,
      manifestFile: manifestFile,
    );
    await expectLater(e.syncUp(), throwsA(isA<GrantLostException>()));
    expect(e.status.state, SyncState.idle);
  });

  test('end-to-end: a seeded SAF folder mirrors up through the engine',
      () async {
    final fake = FakeSafChannel()..install();
    addTearDown(fake.uninstall);
    fake.seedFile(jsonA, utf8.encode('{"a":1}'));
    final imagesDir = fake.seedDir('images');
    fake.seedFile('$idA-1.jpg', [1, 2, 3], parentId: imagesDir);

    final e = SyncEngine(
      source: SafFolderSource(treeUri: fake.treeUri, channel: fake.channel),
      remote: remote,
      manifestFile: manifestFile,
    );
    await e.syncUp();
    expect(remote.files.keys.toSet(), {jsonA, img});
    expect(remote.files[img], [1, 2, 3]);
    expect(e.status.state, SyncState.synced);
  });

  // F5 conflict fence: a remote copy whose rev moved since OUR last upload is
  // skipped + surfaced, never overwritten (senior review 2026-08-08).

  test('F5: remote edited elsewhere → local edit skipped + surfaced, sticky',
      () async {
    await put(jsonA, '{"a":1}');
    final e = engine();
    await e.syncUp(); // records the post-upload rev in the manifest

    // Device B (or the Drive UI) replaces the remote copy: rev moves.
    remote.files[jsonA] = utf8.encode('{"a":"device B edit, longer"}');
    await put(jsonA, '{"a":"device A edit"}');

    await e.syncUp();
    expect(e.status.state, SyncState.synced);
    expect(e.status.conflicts, [jsonA]);
    expect(utf8.decode(remote.files[jsonA]!),
        '{"a":"device B edit, longer"}'); // B's copy survived
    expect(remote.uploads, 1); // nothing re-sent

    await e.syncUp(); // unresolved → surfaces again, still no overwrite
    expect(e.status.conflicts, [jsonA]);
    expect(utf8.decode(remote.files[jsonA]!), '{"a":"device B edit, longer"}');
  });

  test('F5: deleted here + edited there → remote kept, claim released',
      () async {
    await put(jsonA, '{"a":1}');
    final e = engine();
    await e.syncUp();

    remote.files[jsonA] = utf8.encode('{"a":"newer remote"}');
    await File('${folder.path}/$jsonA').delete();

    await e.syncUp();
    expect(e.status.conflicts, [jsonA]);
    expect(remote.deletes, 0); // the newer copy was NOT deleted
    expect(remote.files.containsKey(jsonA), isTrue);

    // Claim released: the next pass neither deletes nor re-surfaces...
    await e.syncUp();
    expect(e.status.conflicts, isEmpty);
    expect(remote.deletes, 0);
    // ...and restoreDown brings the book back (additive).
    expect(await e.restoreDown(), 1);
    expect(await File('${folder.path}/$jsonA').readAsString(),
        '{"a":"newer remote"}');
  });

  test('F5: unmoved rev uploads normally; no-change pass costs zero lists',
      () async {
    await put(jsonA, '{"a":1}');
    final e = engine();
    await e.syncUp();
    final listsAfterFirst = remote.listCalls;

    await e.syncUp(); // nothing changed — the fence must stay lazy
    expect(remote.listCalls, listsAfterFirst);

    await put(jsonA, '{"a":"edited"}'); // remote rev untouched → real upload
    await e.syncUp();
    expect(e.status.conflicts, isEmpty);
    expect(utf8.decode(remote.files[jsonA]!), '{"a":"edited"}');
    expect(remote.uploads, 2);
  });

  test('F5: restoreDown records the remote rev as the fence baseline',
      () async {
    remote.files[jsonA] = utf8.encode('{"a":1}');
    final e = engine();
    expect(await e.restoreDown(), 1);

    // Remote then changes elsewhere; a local edit must hit the fence.
    remote.files[jsonA] = utf8.encode('{"a":"changed elsewhere!"}');
    await put(jsonA, '{"a":"local edit"}');
    await e.syncUp();
    expect(e.status.conflicts, [jsonA]);
    expect(utf8.decode(remote.files[jsonA]!), '{"a":"changed elsewhere!"}');
  });

  // Pantry layout: pantry/<stem>.json + pantry/images/<stem> travel exactly
  // like recipes — and nothing else under pantry/ does.

  const pantryJson = 'pantry/7038010071751.json';
  const pantryImg = 'pantry/images/7038010071751.jpg';

  test('pantry files mirror up; deleting a product deletes its remote copy',
      () async {
    await put(pantryJson, '{"name":"Melk"}');
    await put(pantryImg, 'jpeg-bytes');
    final e = engine();
    await e.syncUp();
    expect(remote.files.keys.toSet(), {pantryJson, pantryImg});
    expect(utf8.decode(remote.files[pantryJson]!), '{"name":"Melk"}');

    await File('${folder.path}/$pantryJson').delete();
    await File('${folder.path}/$pantryImg').delete();
    await e.syncUp();
    expect(remote.deletes, 2); // owned names — deletion propagates
    expect(remote.files, isEmpty);
  });

  test('restoreDown pulls pantry files back into pantry/', () async {
    remote.files[pantryJson] = utf8.encode('{"name":"Melk"}');
    remote.files[pantryImg] = utf8.encode('jpeg-bytes');

    expect(await engine().restoreDown(), 2);
    expect(await File('${folder.path}/$pantryJson').readAsString(),
        '{"name":"Melk"}');
    expect(await File('${folder.path}/$pantryImg').readAsString(),
        'jpeg-bytes');
  });

  test('foreign names under pantry/ are never uploaded', () async {
    await put(pantryJson, '{"name":"Melk"}');
    await put('pantry/notes.txt', 'not a product');
    await engine().syncUp();
    expect(remote.files.keys.toSet(), {pantryJson}); // .txt refused (§7)
  });

  // Safety (b): a manifest written by a PRE-PANTRY app version tracks names
  // as flat relative paths, and that version could never have uploaded (so
  // never tracked) a pantry/ name. "Vanished → remote delete" only fires for
  // TRACKED names missing locally — new pantry files are local-and-untracked,
  // the exact opposite, so they can only upload, never delete.
  test('pre-pantry manifest: pantry files upload as new, nothing vanishes',
      () async {
    const recipeBytes = '{"a":1}';
    final hash = [
      for (final b in sha256(utf8.encode(recipeBytes)))
        b.toRadixString(16).padLeft(2, '0')
    ].join();
    // Byte-exact shape an older engine persisted: only recipe-layout names.
    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString(jsonEncode({
      'files': {
        jsonA: {'size': recipeBytes.length, 'sha256': hash, 'rev': 'r7'},
        img: {'size': 10, 'sha256': 'irrelevant'},
      }
    }));
    remote.files[jsonA] = utf8.encode(recipeBytes);
    await put(jsonA, recipeBytes);
    await put(img, 'jpeg-bytes'); // changed since the old manifest
    await put(pantryJson, '{"name":"Melk"}');
    await put(pantryImg, 'photo');

    final e = engine();
    await e.syncUp();

    expect(remote.deletes, 0); // NOTHING read as vanished
    expect(remote.files.keys.toSet(), {jsonA, img, pantryJson, pantryImg});
    expect(remote.uploads, 3); // pantry pair + changed image; jsonA hash held
    expect(e.status.state, SyncState.synced);
  });

  // Safety (c): to a PRE-PANTRY client a remote pantry/ folder is just an
  // unknown-subdir name — and this engine's treatment of unknown-subdir
  // names is version-independent: restore refuses them (safeName), and a
  // tracked one is dropped from tracking, never deleted (_ownedName fence).
  // 'meals/' stands in for what 'pantry/' is to the old client; the same
  // mechanism protects any future layout dir from THIS client.
  test('unknown-subdir remote names: restore skips, tracking drops, no delete',
      () async {
    remote.files['meals/1.json'] = utf8.encode('{"future":true}');
    // Worst case: the name somehow ended up tracked.
    await manifestFile.parent.create(recursive: true);
    await manifestFile.writeAsString(jsonEncode({
      'files': {
        'meals/1.json': {'size': 15, 'sha256': 'whatever'}
      }
    }));

    final e = engine();
    expect(await e.restoreDown(), 0); // refused, not downloaded
    expect(await File('${folder.path}/1.json').exists(), isFalse);

    await e.syncUp(); // 'meals/1.json' is tracked but not local → vanished
    expect(remote.deletes, 0); // fence held: dropped from tracking instead
    expect(remote.files.containsKey('meals/1.json'), isTrue);

    await e.syncUp(); // second pass proves the claim is gone, still no delete
    expect(remote.deletes, 0);
    expect(remote.files.containsKey('meals/1.json'), isTrue);
  });
}
