// What sync mirrors: the user's folder, addressed by the relative layout —
// one segment at the root ('<id>.json'), 'images/<segment>', and the pantry
// twins 'pantry/<segment>.json' + 'pantry/images/<segment>'. Exactly the
// RecipeStore + ProductStore shapes (arch §4); sources read it for
// hashing/upload and write it only on restore. Name confinement (§7):
// anything outside those four shapes is refused, so a hostile remote can
// never write outside the folder.

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

  /// One segment ('x.json'), `images/segment`, `pantry/segment.json` or
  /// `pantry/images/segment` — the whole sync layout. Exactly these four
  /// shapes; everything else (traversal, deeper nesting, unknown dirs,
  /// non-JSON pantry root files) is refused by design (§7).
  static bool safeName(String name) {
    bool seg(String s) =>
        s.isNotEmpty &&
        s != '.' &&
        s != '..' &&
        !s.contains('/') &&
        !s.contains('\\');
    if (name.startsWith('images/')) return seg(name.substring('images/'.length));
    if (name.startsWith('pantry/images/')) {
      return seg(name.substring('pantry/images/'.length));
    }
    if (name.startsWith('pantry/')) {
      final s = name.substring('pantry/'.length);
      // Pantry root mirrors product files only — '<stem>.json', nothing else.
      return s.endsWith('.json') && seg(s);
    }
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
    // Stranded atomic-write leftovers are not content: an uploaded .tmp
    // could never be deleted remotely (_ownedName wants .json$).
    Future<void> addDir(String prefix, Directory dir) async {
      if (!await dir.exists()) return;
      await for (final e in dir.list()) {
        if (e is! File) continue;
        final name = '$prefix${e.uri.pathSegments.last}';
        if (name.endsWith('.tmp')) continue;
        entries[name] = SourceEntry(name: name, size: await e.length());
      }
    }

    await addDir('', root);
    await addDir('images/', Directory('${root.path}/images'));
    await addDir('pantry/', Directory('${root.path}/pantry'));
    await addDir('pantry/images/', Directory('${root.path}/pantry/images'));
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
  String? _pantryDirId;
  Map<String, String>? _pantryFiles; // name → docId inside pantry/
  String? _pantryImagesDirId;
  Map<String, String>? _pantryImageFiles; // name → docId inside pantry/images/

  // The real bridge creates a directory through createDocument with this
  // exact mime (DocumentsContract.Document.MIME_TYPE_DIR) — how createFile
  // makes 'pantry/images' under a non-root parent (createDir is root-only).
  static const _dirMime = 'vnd.android.document/directory';

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
    String? pantryDirId;
    for (final row in await _listChildren(null)) {
      final name = row['name'] as String? ?? '';
      final docId = row['docId'] as String? ?? '';
      if (row['isDir'] == true) {
        if (name == 'images') imagesDirId = docId;
        if (name == 'pantry') pantryDirId = docId;
      } else {
        rootFiles[name] = docId;
      }
    }
    Future<Map<String, String>> files(String? dirId,
        {void Function(String name, String docId)? onDir}) async {
      final found = <String, String>{};
      if (dirId == null) return found;
      for (final row in await _listChildren(dirId)) {
        final name = row['name'] as String? ?? '';
        final docId = row['docId'] as String? ?? '';
        if (row['isDir'] == true) {
          onDir?.call(name, docId);
        } else {
          found[name] = docId;
        }
      }
      return found;
    }

    final imageFiles = await files(imagesDirId);
    String? pantryImagesDirId;
    final pantryFiles = await files(pantryDirId, onDir: (name, docId) {
      if (name == 'images') pantryImagesDirId = docId;
    });
    final pantryImageFiles = await files(pantryImagesDirId);
    _rootFiles = rootFiles;
    _imagesDirId = imagesDirId;
    _imageFiles = imageFiles;
    _pantryDirId = pantryDirId;
    _pantryFiles = pantryFiles;
    _pantryImagesDirId = pantryImagesDirId;
    _pantryImageFiles = pantryImageFiles;
    return {
      for (final name in rootFiles.keys)
        name: SourceEntry(name: name, size: -1),
      for (final name in imageFiles.keys)
        'images/$name': SourceEntry(name: 'images/$name', size: -1),
      for (final name in pantryFiles.keys)
        'pantry/$name': SourceEntry(name: 'pantry/$name', size: -1),
      for (final name in pantryImageFiles.keys)
        'pantry/images/$name':
            SourceEntry(name: 'pantry/images/$name', size: -1),
    };
  }

  // Longest prefix first — 'pantry/images/x' must never match 'pantry/'.
  Map<String, String> _dirOf(String name) {
    if (name.startsWith('pantry/images/')) return _pantryImageFiles!;
    if (name.startsWith('pantry/')) return _pantryFiles!;
    if (name.startsWith('images/')) return _imageFiles!;
    return _rootFiles!;
  }

  static String _leaf(String name) =>
      name.substring(name.lastIndexOf('/') + 1);

  @override
  Future<List<int>> read(String name) async {
    await _ensureIndex();
    final docId = _dirOf(name)[_leaf(name)];
    if (docId == null) throw SyncIoException('read $name: not in folder');
    return await _invoke<Uint8List>(
        'readFile', {'treeUri': treeUri, 'docId': docId});
  }

  Future<String> _ensurePantryDir() async =>
      _pantryDirId ??= await _invoke<String>(
          'createDir', {'treeUri': treeUri, 'name': 'pantry'});

  @override
  Future<void> write(String name, List<int> bytes) async {
    if (!SyncSource.safeName(name)) throw ArgumentError('unsafe name: $name');
    await _ensureIndex();
    final leaf = _leaf(name);
    // Existing docId must win over createFile in every branch, or SAF
    // auto-renames to 'x (1)' (saf_store discipline).
    Future<String> create(String parentDocId) =>
        _invoke<String>('createFile', {
          'treeUri': treeUri,
          'parentDocId': parentDocId,
          'name': leaf,
          'mime': _sourceMime(leaf),
        });
    final String docId;
    if (name.startsWith('pantry/images/')) {
      final pantryDirId = await _ensurePantryDir();
      _pantryImagesDirId ??= await _invoke<String>('createFile', {
        'treeUri': treeUri,
        'parentDocId': pantryDirId,
        'name': 'images',
        'mime': _dirMime,
      });
      docId = _pantryImageFiles![leaf] ??= await create(_pantryImagesDirId!);
    } else if (name.startsWith('pantry/')) {
      final pantryDirId = await _ensurePantryDir();
      docId = _pantryFiles![leaf] ??= await create(pantryDirId);
    } else if (name.startsWith('images/')) {
      _imagesDirId ??= await _invoke<String>(
          'createDir', {'treeUri': treeUri, 'name': 'images'});
      docId = _imageFiles![leaf] ??= await create(_imagesDirId!);
    } else {
      docId = _rootFiles![name] ??= await create(_rootDocId);
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
