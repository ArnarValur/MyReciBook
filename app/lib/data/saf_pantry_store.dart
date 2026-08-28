// SAF document-tree impl of ProductStore (saf_store.dart's discipline applied
// to the pantry): same layout as LocalPantryStore — <stem>.json + images/ —
// but rooted at the 'pantry/' subdir of the user-picked tree, so products
// live and sync beside the recipes. Scan strategy: ONE child-documents query
// per directory, held as an in-memory name→docId map; per-file lookups are
// banned (§4). Lost grant surfaces as GrantLostException for the re-pick
// flow, never a crash (§7).
//
// ProductStore.imageFile is synchronous (the pantry rows read it in build),
// so SAF image bytes are hydrated into [imageCache] eagerly: listAll fills
// cache misses, attachImage writes through. imageFile itself is pure path
// math — a not-yet-hydrated photo reads as absent until the next rescan.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/product.dart';
import 'product_store.dart';
import 'recipe_store.dart' show RecipeStore;
import 'saf_store.dart' show GrantLostException, StoreIoException;

class SafPantryStore implements ProductStore {
  SafPantryStore({
    required this.treeUri,
    required this.imageCache,
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  /// Tree URI of the user-picked folder (the recipes' tree — pantry is its
  /// 'pantry/' subdir).
  final String treeUri;

  /// App-private dir where SAF image bytes are hydrated so Image.file gets a
  /// real File; keyed by ref basename, disposable.
  final Directory imageCache;

  final MethodChannel channel;

  // Session index (D4: rescan per session, no persisted cache). Pantry dir
  // refreshed on every listAll; images/ listed lazily on first need.
  String? _dirId; // the pantry/ dir inside the tree, null until found/created
  Map<String, String>? _files; // name -> docId, files inside pantry/
  String? _imagesDirId;
  Map<String, String>? _imageFiles; // name -> docId, inside pantry/images/

  // The real bridge creates a directory through createDocument with this
  // exact mime (DocumentsContract.Document.MIME_TYPE_DIR); createDir itself
  // only creates at the tree root.
  static const _dirMime = 'vnd.android.document/directory';

  static bool _safeId(String id) => RecipeStore.safeId(id);

  static bool _safeRef(String ref) =>
      RegExp(r'^images/[A-Za-z0-9._-]+$').hasMatch(ref) && !ref.contains('..');

  Future<T> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return await channel.invokeMethod<T>(method, args) as T;
    } on PlatformException catch (e) {
      if (e.code == 'GRANT_LOST') {
        throw GrantLostException(e.message ?? 'grant lost');
      }
      rethrow; // SAF_IO — callers decide skip vs save failure
    }
  }

  Future<List<Map<String, Object?>>> _listChildren(String? parentDocId) async {
    final rows = await _invoke<List<dynamic>>(
        'listChildren', {'treeUri': treeUri, 'parentDocId': parentDocId});
    return [for (final r in rows) (r as Map).cast<String, Object?>()];
  }

  // ONE round trip for a directory's worth of file bytes (§4). A child the
  // bridge could not read is absent from the map — the caller counts the gap.
  Future<Map<String, Uint8List>> _readChildFiles(
      String? parentDocId, String suffix) async {
    final raw = await _invoke<Map<dynamic, dynamic>>('readChildFiles', {
      'treeUri': treeUri,
      'parentDocId': parentDocId,
      'suffix': suffix,
    });
    return raw.cast<String, Uint8List>();
  }

  Future<void> _refresh() async {
    String? dirId;
    for (final row in await _listChildren(null)) {
      if (row['isDir'] == true && row['name'] == 'pantry') {
        dirId = row['docId'] as String? ?? '';
      }
    }
    final files = <String, String>{};
    String? imagesDirId;
    if (dirId != null) {
      for (final row in await _listChildren(dirId)) {
        final name = row['name'] as String? ?? '';
        final docId = row['docId'] as String? ?? '';
        if (row['isDir'] == true) {
          if (name == 'images') imagesDirId = docId;
        } else {
          files[name] = docId;
        }
      }
    }
    _dirId = dirId;
    _files = files;
    _imagesDirId = imagesDirId;
    _imageFiles = null;
  }

  Future<Map<String, String>> _root() async {
    if (_files == null) await _refresh();
    return _files!;
  }

  Future<Map<String, String>> _images() async {
    await _root();
    if (_imageFiles != null) return _imageFiles!;
    if (_imagesDirId == null) return _imageFiles = {};
    final rows = await _listChildren(_imagesDirId);
    return _imageFiles = {
      for (final row in rows)
        if (row['isDir'] != true)
          (row['name'] as String? ?? ''): (row['docId'] as String? ?? '')
    };
  }

  Future<String> _ensureDir() async =>
      _dirId ??= await _invoke<String>(
          'createDir', {'treeUri': treeUri, 'name': 'pantry'});

  Future<String> _ensureImagesDir() async {
    final dirId = await _ensureDir();
    if (_imagesDirId == null) {
      _imagesDirId = await _invoke<String>('createFile', {
        'treeUri': treeUri,
        'parentDocId': dirId,
        'name': 'images',
        'mime': _dirMime,
      });
      _imageFiles = {};
    }
    return _imagesDirId!;
  }

  @override
  Future<PantryResult> listAll() async {
    await _refresh();
    final products = <Product>[];
    var skipped = 0;
    final names = [
      for (final name in _files!.keys)
        if (name.endsWith('.json')) name
    ];
    // GrantLostException out of the batch propagates untouched — the per-name
    // catch below only ever sees decode/schema failures.
    final batch = names.isEmpty
        ? const <String, Uint8List>{}
        : await _readChildFiles(_dirId, '.json');
    for (final name in names) {
      final bytes = batch[name];
      if (bytes == null) {
        skipped++; // listed but unreadable: counted, never fatal (§7)
        continue;
      }
      try {
        final json = jsonDecode(utf8.decode(bytes, allowMalformed: true))
            as Map<String, dynamic>;
        if (productProblems(json).isNotEmpty) {
          skipped++;
          continue;
        }
        products.add(Product.fromJson(json));
      } catch (_) {
        skipped++; // foreign/corrupt: counted, never fatal (§7)
      }
    }
    for (final p in products) {
      await _hydrateImage(p); // cache misses only; sync imageFile stays honest
    }
    products.sort((a, b) => (b.addedAt ?? '').compareTo(a.addedAt ?? ''));
    return PantryResult(products, skipped);
  }

  @override
  Future<Product?> load(String id) async {
    if (!_safeId(id)) return null;
    final docId = (await _root())['$id.json'];
    if (docId == null) return null;
    try {
      final bytes = await _invoke<Uint8List>(
          'readFile', {'treeUri': treeUri, 'docId': docId});
      return Product.fromJson(
          jsonDecode(utf8.decode(bytes, allowMalformed: true))
              as Map<String, dynamic>);
    } on GrantLostException {
      rethrow;
    } catch (_) {
      return null; // corrupt file: same never-fatal stance as listAll (§7)
    }
  }

  @override
  Future<Product> save(Product product) async {
    final blocking = productProblems(product.toJson());
    if (!_safeId(product.id)) blocking.add('unsafe id "${product.id}"');
    if (blocking.isNotEmpty) {
      throw StateError(
          'refusing to save invalid product: ${blocking.join('; ')}');
    }
    try {
      final files = await _root();
      final dirId = await _ensureDir();
      final name = '${product.id}.json';
      // Existing docId first — never let SAF auto-rename create "x (1)".
      final docId = files[name] ??
          await _invoke<String>('createFile', {
            'treeUri': treeUri,
            'parentDocId': dirId,
            'name': name,
            'mime': 'application/json',
          });
      files[name] = docId;
      await _invoke<void>('writeFile', {
        'treeUri': treeUri,
        'docId': docId,
        'bytes': Uint8List.fromList(utf8.encode(
            const JsonEncoder.withIndent('  ').convert(product.toJson()))),
      });
      return product;
    } on PlatformException catch (e) {
      // SAF_IO mid-save: same failure class the UI already shows.
      throw StoreIoException('save failed: ${e.message ?? e.code}');
    }
  }

  @override
  Future<Product> update(Product product) async {
    if (!_safeId(product.id) ||
        !(await _root()).containsKey('${product.id}.json')) {
      throw StateError('cannot update unknown product "${product.id}"');
    }
    return save(product);
  }

  static const _imageExts = ['jpg', 'png'];

  @override
  Future<void> delete(String id) async {
    if (!_safeId(id)) return;
    final files = await _root();
    final docId = files['$id.json'];
    if (docId != null) {
      await _invoke<bool>('deleteFile', {'treeUri': treeUri, 'docId': docId});
      files.remove('$id.json');
    }
    // The photo goes with the product (covers rule: delete takes the cover).
    for (final ext in _imageExts) {
      try {
        final images = await _images();
        final imgDocId = images['$id.$ext'];
        if (imgDocId != null) {
          await _invoke<bool>(
              'deleteFile', {'treeUri': treeUri, 'docId': imgDocId});
          images.remove('$id.$ext');
        }
      } on GrantLostException {
        rethrow;
      } on PlatformException {
        // images/ vanished externally: JSON is already gone, cleanup is
        // best-effort (§7) — the hydrated copy below still gets removed.
      }
      final cached = File('${imageCache.path}/$id.$ext');
      if (await cached.exists()) await cached.delete();
    }
  }

  @override
  Future<Product> attachImage(Product product, File photo) async {
    if (!_safeId(product.id)) {
      throw StateError('unsafe id "${product.id}"');
    }
    try {
      final ext = photo.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final name = '${product.id}.$ext';
      final imagesDirId = await _ensureImagesDir();
      final images = await _images();
      final docId = images[name] ??
          await _invoke<String>('createFile', {
            'treeUri': treeUri,
            'parentDocId': imagesDirId,
            'name': name,
            'mime': ext == 'png' ? 'image/png' : 'image/jpeg',
          });
      images[name] = docId;
      final bytes = await photo.readAsBytes();
      await _invoke<void>('writeFile', {
        'treeUri': treeUri,
        'docId': docId,
        'bytes': Uint8List.fromList(bytes),
      });
      // Write-through hydration: the sync imageFile must see the new bytes.
      await imageCache.create(recursive: true);
      await File('${imageCache.path}/$name').writeAsBytes(bytes);
      // Replacing jpg with png (or back) must not strand the old bytes.
      for (final other in _imageExts) {
        if (other == ext) continue;
        await _dropImageFile('${product.id}.$other');
      }
      return await save(product.copyWith(image: 'images/$name'));
    } on PlatformException catch (e) {
      throw StoreIoException('attach failed: ${e.message ?? e.code}');
    }
  }

  @override
  Future<Product> removeImage(Product product) async {
    final ref = product.image;
    try {
      if (ref != null && _safeRef(ref)) {
        await _dropImageFile(ref.substring('images/'.length));
      }
      return await save(product.copyWith(clearImage: true));
    } on PlatformException catch (e) {
      throw StoreIoException('remove image failed: ${e.message ?? e.code}');
    }
  }

  Future<void> _dropImageFile(String name) async {
    final images = await _images();
    final docId = images[name];
    if (docId != null) {
      await _invoke<bool>('deleteFile', {'treeUri': treeUri, 'docId': docId});
      images.remove(name);
    }
    final cached = File('${imageCache.path}/$name');
    if (await cached.exists()) await cached.delete();
  }

  @override
  File? imageFile(Product product) {
    final ref = product.image;
    // Confinement (§7): only our own layout resolves — a foreign file's ref
    // must never escape the cache dir.
    if (ref == null || !_safeRef(ref)) return null;
    return File('${imageCache.path}/${ref.substring('images/'.length)}');
  }

  /// SAF read-back of the product's photo — bypasses the hydration cache, so
  /// the pantry migration can verify bytes actually landed in the tree.
  /// Null when unset, foreign, missing, or unreadable (non-grant).
  Future<List<int>?> imageBytes(Product product) async {
    final ref = product.image;
    if (ref == null || !_safeRef(ref)) return null;
    final docId = (await _images())[ref.substring('images/'.length)];
    if (docId == null) return null;
    try {
      return await _invoke<Uint8List>(
          'readFile', {'treeUri': treeUri, 'docId': docId});
    } on GrantLostException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  Future<void> _hydrateImage(Product product) async {
    final target = imageFile(product);
    if (target == null || await target.exists()) return;
    final bytes = await imageBytes(product);
    if (bytes == null) return; // unreadable image: placeholder, not a crash
    await imageCache.create(recursive: true);
    await target.writeAsBytes(bytes);
  }
}
