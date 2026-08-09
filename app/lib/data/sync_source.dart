// What sync mirrors: the user's folder, addressed by the relative layout —
// one segment at the root ('<id>.json') or 'images/<segment>'. Exactly the
// RecipeStore shape (arch §4); sources read it for hashing/upload and write
// it only on restore. Name confinement (§7): anything outside those two
// shapes is refused, so a hostile remote can never write outside the folder.

import 'dart:io';

import 'package:flutter/services.dart';

import 'remote_store.dart' show SyncIoException;
import 'saf_store.dart' show GrantLostException;

/// One source file. [size] is -1 when the backend can't tell (the SAF
/// listing carries no size) — the engine hashes content, never trusts size.
class SourceEntry {
  final String name;
  final int size;

  const SourceEntry({required this.name, required this.size});
}

abstract class SyncSource {
  Future<Map<String, SourceEntry>> list();
  Future<List<int>> read(String name);
  Future<void> write(String name, List<int> bytes);

  /// One segment ('x.json') or `images/segment` — the whole sync layout.
  static bool safeName(String name) {
    bool seg(String s) =>
        s.isNotEmpty &&
        s != '.' &&
        s != '..' &&
        !s.contains('/') &&
        !s.contains('\\');
    if (name.startsWith('images/')) return seg(name.substring('images/'.length));
    return seg(name);
  }
}

/// dart:io folder — tests and the pre-SAF local store.
class LocalFolderSource implements SyncSource {
  LocalFolderSource(this.root);

  final Directory root;

  File _file(String name) {
    if (!SyncSource.safeName(name)) throw ArgumentError('unsafe name: $name');
    return File('${root.path}/$name');
  }

  @override
  Future<Map<String, SourceEntry>> list() async {
    final entries = <String, SourceEntry>{};
    if (!await root.exists()) return entries;
    await for (final e in root.list()) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.last;
      // Stranded atomic-write leftovers are not content: an uploaded .tmp
      // could never be deleted remotely (_ownedName wants .json$).
      if (name.endsWith('.tmp')) continue;
      entries[name] = SourceEntry(name: name, size: await e.length());
    }
    final images = Directory('${root.path}/images');
    if (await images.exists()) {
      await for (final e in images.list()) {
        if (e is! File) continue;
        final name = 'images/${e.uri.pathSegments.last}';
        if (name.endsWith('.tmp')) continue;
        entries[name] = SourceEntry(name: name, size: await e.length());
      }
    }
    return entries;
  }

  @override
  Future<List<int>> read(String name) async {
    try {
      return await _file(name).readAsBytes();
    } on FileSystemException catch (e) {
      throw SyncIoException('read $name: ${e.message}'); // transient → offline
    }
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    final f = _file(name);
    try {
      await f.parent.create(recursive: true);
      await f.writeAsBytes(bytes, flush: true);
    } on FileSystemException catch (e) {
      throw SyncIoException('write $name: ${e.message}');
    }
  }
}

/// SAF document-tree source. One listChildren per dir (§4), name→docId maps
/// cached per list() and kept current by write() — an existing docId must win
/// over createFile, or SAF auto-renames to 'x (1)' (saf_store discipline).
class SafFolderSource implements SyncSource {
  SafFolderSource({
    required this.treeUri,
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  final String treeUri;
  final MethodChannel channel;

  Map<String, String>? _rootFiles; // name → docId at the tree root
  String? _imagesDirId;
  Map<String, String>? _imageFiles; // name → docId inside images/

  // DocumentsContract.getTreeDocumentId — the tree URI's second path segment.
  String get _rootDocId {
    final segs = Uri.parse(treeUri).pathSegments;
    return segs.length > 1 ? segs[1] : '';
  }

  Future<T> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return await channel.invokeMethod<T>(method, args) as T;
    } on PlatformException catch (e) {
      if (e.code == 'GRANT_LOST') {
        throw GrantLostException(e.message ?? 'grant lost'); // re-pick flow
      }
      throw SyncIoException('$method: ${e.message ?? e.code}'); // SAF_IO
    }
  }

  Future<List<Map<String, Object?>>> _listChildren(String? parentDocId) async {
    final rows = await _invoke<List<dynamic>>(
        'listChildren', {'treeUri': treeUri, 'parentDocId': parentDocId});
    return [for (final r in rows) (r as Map).cast<String, Object?>()];
  }

  Future<void> _ensureIndex() async {
    if (_rootFiles == null) await list();
  }

  @override
  Future<Map<String, SourceEntry>> list() async {
    final rootFiles = <String, String>{};
    String? imagesDirId;
    for (final row in await _listChildren(null)) {
      final name = row['name'] as String? ?? '';
      final docId = row['docId'] as String? ?? '';
      if (row['isDir'] == true) {
        if (name == 'images') imagesDirId = docId;
      } else {
        rootFiles[name] = docId;
      }
    }
    final imageFiles = <String, String>{};
    if (imagesDirId != null) {
      for (final row in await _listChildren(imagesDirId)) {
        if (row['isDir'] == true) continue;
        imageFiles[row['name'] as String? ?? ''] = row['docId'] as String? ?? '';
      }
    }
    _rootFiles = rootFiles;
    _imagesDirId = imagesDirId;
    _imageFiles = imageFiles;
    return {
      for (final name in rootFiles.keys)
        name: SourceEntry(name: name, size: -1),
      for (final name in imageFiles.keys)
        'images/$name': SourceEntry(name: 'images/$name', size: -1),
    };
  }

  @override
  Future<List<int>> read(String name) async {
    await _ensureIndex();
    final docId = name.startsWith('images/')
        ? _imageFiles![name.substring('images/'.length)]
        : _rootFiles![name];
    if (docId == null) throw SyncIoException('read $name: not in folder');
    return await _invoke<Uint8List>(
        'readFile', {'treeUri': treeUri, 'docId': docId});
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    if (!SyncSource.safeName(name)) throw ArgumentError('unsafe name: $name');
    await _ensureIndex();
    final String docId;
    if (name.startsWith('images/')) {
      final leaf = name.substring('images/'.length);
      _imagesDirId ??= await _invoke<String>(
          'createDir', {'treeUri': treeUri, 'name': 'images'});
      docId = _imageFiles![leaf] ??= await _invoke<String>('createFile', {
        'treeUri': treeUri,
        'parentDocId': _imagesDirId,
        'name': leaf,
        'mime': _sourceMime(leaf),
      });
    } else {
      docId = _rootFiles![name] ??= await _invoke<String>('createFile', {
        'treeUri': treeUri,
        'parentDocId': _rootDocId,
        'name': name,
        'mime': _sourceMime(name),
      });
    }
    await _invoke<void>('writeFile', {
      'treeUri': treeUri,
      'docId': docId,
      'bytes': Uint8List.fromList(bytes),
    });
  }
}

String _sourceMime(String name) {
  final n = name.toLowerCase();
  if (n.endsWith('.json')) return 'application/json';
  if (n.endsWith('.png')) return 'image/png';
  if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
  return 'application/octet-stream';
}
