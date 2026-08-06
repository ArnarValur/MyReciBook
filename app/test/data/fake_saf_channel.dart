// In-memory document tree faithful to the SafBridge platform contract:
// auto-rename on name collision (returned docId reflects it, name is not
// re-reported), GRANT_LOST after revoke — except pickFolder / hasGrant /
// deleteFile / releaseGrant, which never emit it — and SAF_IO for the rest.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSafDoc {
  FakeSafDoc({
    required this.name,
    required this.isDir,
    this.parent,
    Uint8List? bytes,
    this.mime = '',
  }) : bytes = bytes ?? Uint8List(0);

  final String name;
  final bool isDir;
  final String? parent; // parent docId; null only for the tree root
  Uint8List bytes;
  final String mime;
}

class FakeSafChannel {
  FakeSafChannel() {
    docs[rootId] = FakeSafDoc(name: '', isDir: true);
  }

  /// Must equal the tree URI's second path segment (DocumentsContract
  /// getTreeDocumentId), which SafFolderStore derives for root createFile.
  static const rootId = 'root-id';
  final String treeUri = 'content://fake.saf/tree/root-id';
  final MethodChannel channel = const MethodChannel('fake-saf-test');

  final Map<String, FakeSafDoc> docs = {};
  bool revoked = false;
  int reads = 0; // readFile calls — cache-hit assertions
  int failWrites = 0; // next N writeFile calls fail SAF_IO (transient hiccup)
  int _seq = 0;

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, _call);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  }

  // ---- direct tree access for seeding/asserting -------------------------

  String? findId(String name, {String parentId = rootId}) {
    for (final e in docs.entries) {
      if (e.value.parent == parentId && e.value.name == name) return e.key;
    }
    return null;
  }

  FakeSafDoc? find(String name, {String parentId = rootId}) {
    final id = findId(name, parentId: parentId);
    return id == null ? null : docs[id];
  }

  Iterable<FakeSafDoc> childrenOf(String parentId) =>
      docs.values.where((d) => d.parent == parentId);

  String seedFile(String name, List<int> bytes,
      {String parentId = rootId, String mime = ''}) {
    final id = 'seed-${++_seq}';
    docs[id] = FakeSafDoc(
        name: name,
        isDir: false,
        parent: parentId,
        bytes: Uint8List.fromList(bytes),
        mime: mime);
    return id;
  }

  String seedDir(String name, {String parentId = rootId}) {
    final id = 'seed-${++_seq}';
    docs[id] = FakeSafDoc(
        name: name,
        isDir: true,
        parent: parentId,
        mime: 'vnd.android.document/directory');
    return id;
  }

  // ---- the platform contract --------------------------------------------

  Future<Object?> _call(MethodCall call) async {
    final args = call.arguments is Map
        ? (call.arguments as Map).cast<String, Object?>()
        : <String, Object?>{};
    // These four never emit GRANT_LOST (bridge contract).
    switch (call.method) {
      case 'pickFolder':
        return treeUri;
      case 'hasGrant':
        return !revoked;
      case 'releaseGrant':
        return null;
      case 'deleteFile':
        if (revoked) return false;
        final id = args['docId'] as String?;
        if (id == null || !docs.containsKey(id) || id == rootId) return false;
        _removeTree(id);
        return true;
    }
    if (revoked) {
      throw PlatformException(code: 'GRANT_LOST', message: 'grant revoked');
    }
    switch (call.method) {
      case 'listChildren':
        final parent = (args['parentDocId'] as String?) ?? rootId;
        final dir = docs[parent];
        if (dir == null || !dir.isDir) {
          throw PlatformException(code: 'SAF_IO', message: 'no such dir $parent');
        }
        return [
          for (final e in docs.entries)
            if (e.value.parent == parent)
              {
                'docId': e.key,
                'name': e.value.name,
                'mime': e.value.mime,
                'isDir': e.value.isDir,
              }
        ];
      case 'readFile':
        final doc = docs[args['docId']];
        if (doc == null || doc.isDir) {
          throw PlatformException(code: 'SAF_IO', message: 'not found');
        }
        reads++;
        return doc.bytes;
      case 'createFile':
        return _create(
            args['parentDocId'] as String?, args['name'] as String?,
            args['mime'] as String? ?? '',
            isDir: false);
      case 'createDir':
        return _create(rootId, args['name'] as String?,
            'vnd.android.document/directory',
            isDir: true);
      case 'writeFile':
        if (failWrites > 0) {
          failWrites--;
          throw PlatformException(code: 'SAF_IO', message: 'transient write');
        }
        final doc = docs[args['docId']];
        if (doc == null || doc.isDir || args['bytes'] == null) {
          throw PlatformException(code: 'SAF_IO', message: 'not found');
        }
        doc.bytes = Uint8List.fromList((args['bytes'] as List).cast<int>());
        return null;
    }
    throw PlatformException(code: 'SAF_IO', message: 'unknown ${call.method}');
  }

  String _create(String? parentId, String? name, String mime,
      {required bool isDir}) {
    final dir = parentId == null ? null : docs[parentId];
    if (name == null || dir == null || !dir.isDir) {
      throw PlatformException(code: 'SAF_IO', message: 'missing argument');
    }
    final id = 'doc-${++_seq}';
    docs[id] = FakeSafDoc(
        name: _dedupeName(parentId!, name),
        isDir: isDir,
        parent: parentId,
        mime: mime);
    return id;
  }

  // Providers auto-rename collisions: "name.ext" → "name (1).ext".
  String _dedupeName(String parentId, String name) {
    bool taken(String n) =>
        docs.values.any((d) => d.parent == parentId && d.name == n);
    if (!taken(name)) return name;
    final dot = name.lastIndexOf('.');
    final base = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var n = 1;
    while (taken('$base ($n)$ext')) {
      n++;
    }
    return '$base ($n)$ext';
  }

  void _removeTree(String id) {
    final children = [
      for (final e in docs.entries)
        if (e.value.parent == id) e.key
    ];
    docs.remove(id);
    children.forEach(_removeTree);
  }
}
