// Storage (architecture §4 applied to the pantry): one <stem>.json per
// product in a pantry folder the user owns, beside their recipes. Stem =
// barcode (scanned) or name slug (manual), so re-scanning a barcode
// overwrites its own file — update, never a duplicate. No images: products
// are JSON-only, which keeps the layout one flat folder of .json files.

import 'dart:convert';
import 'dart:io';

import '../domain/product.dart';
import 'atomic_file.dart';
import 'recipe_store.dart' show RecipeStore;

class PantryResult {
  final List<Product> products;

  /// Foreign or unparseable files skipped during scan — counted, never fatal
  /// (architecture §7: a hostile folder must not take down the list screen).
  final int skipped;

  const PantryResult(this.products, this.skipped);
}

abstract class ProductStore {
  Future<PantryResult> listAll();
  Future<Product?> load(String id);

  /// Validates and writes `<product.id>.json`. Upsert by construction: the
  /// stem derives from barcode/name, so saving the same barcode twice
  /// rewrites one file. Throws [StateError] on save-blocking problems.
  Future<Product> save(Product product);

  /// Save-that-must-hit: throws [StateError] when no file exists for
  /// [Product.id]. Callers that mean "create or overwrite" use [save].
  Future<Product> update(Product product);
  Future<void> delete(String id);

  /// Copies the user's photo into `images/<id>.<ext>` and saves the product
  /// with the ref — the recipe-cover contract: replace cleans up a
  /// jpg↔png leftover, [removeImage] takes the bytes, [delete] takes the
  /// photo with the product.
  Future<Product> attachImage(Product product, File photo);
  Future<Product> removeImage(Product product);

  /// Resolves a product's image ref to a file, or null when unset/foreign.
  File? imageFile(Product product);
}

class LocalPantryStore implements ProductStore {
  final Directory root;

  LocalPantryStore(this.root);

  // Arch §7 confinement, shared with recipes: a foreign JSON's stem must
  // never resolve outside the store.
  static bool _safeId(String id) => RecipeStore.safeId(id);

  File _file(String id) => File('${root.path}/$id.json');

  @override
  Future<PantryResult> listAll() async {
    if (!await root.exists()) return const PantryResult([], 0);
    final products = <Product>[];
    var skipped = 0;
    await for (final entity in root.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        if (productProblems(json).isNotEmpty) {
          skipped++;
          continue;
        }
        products.add(Product.fromJson(json));
      } catch (_) {
        skipped++;
      }
    }
    products.sort((a, b) => (b.addedAt ?? '').compareTo(a.addedAt ?? ''));
    return PantryResult(products, skipped);
  }

  @override
  Future<Product?> load(String id) async {
    if (!_safeId(id)) return null;
    final file = _file(id);
    if (!await file.exists()) return null;
    try {
      return Product.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt file: same never-fatal stance as listAll (§7)
    }
  }

  @override
  Future<Product> save(Product product) async {
    final blocking = productProblems(product.toJson());
    if (!_safeId(product.id)) blocking.add('unsafe id "${product.id}"');
    if (blocking.isNotEmpty) {
      throw StateError('refusing to save invalid product: ${blocking.join('; ')}');
    }
    await root.create(recursive: true);
    // Atomic + serialized (writeStringAtomic): a mid-write kill must never
    // leave a truncated <stem>.json where a good one stood.
    await writeStringAtomic(
        _file(product.id), const JsonEncoder.withIndent('  ').convert(product.toJson()));
    return product;
  }

  @override
  Future<Product> update(Product product) async {
    if (!_safeId(product.id) || !await _file(product.id).exists()) {
      throw StateError('cannot update unknown product "${product.id}"');
    }
    return save(product);
  }

  @override
  Future<void> delete(String id) async {
    if (!_safeId(id)) return;
    final file = _file(id);
    if (await file.exists()) await file.delete();
    // A stranded atomic-write leftover holds the full product JSON — a
    // deleted product must not survive in its .tmp shadow.
    final tmp = File('${file.path}.tmp');
    if (await tmp.exists()) await tmp.delete();
    // The photo goes with the product (covers rule: delete takes the cover).
    for (final ext in _imageExts) {
      final img = File('${root.path}/images/$id.$ext');
      if (await img.exists()) await img.delete();
    }
  }

  static const _imageExts = ['jpg', 'png'];

  @override
  Future<Product> attachImage(Product product, File photo) async {
    if (!_safeId(product.id)) {
      throw StateError('unsafe id "${product.id}"');
    }
    final ext =
        photo.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    await Directory('${root.path}/images').create(recursive: true);
    await photo.copy('${root.path}/images/${product.id}.$ext');
    // Replacing jpg with png (or back) must not strand the old bytes.
    for (final other in _imageExts) {
      if (other == ext) continue;
      final stale = File('${root.path}/images/${product.id}.$other');
      if (await stale.exists()) await stale.delete();
    }
    return save(product.copyWith(image: 'images/${product.id}.$ext'));
  }

  @override
  Future<Product> removeImage(Product product) async {
    final file = imageFile(product);
    if (file != null && await file.exists()) await file.delete();
    return save(product.copyWith(clearImage: true));
  }

  @override
  File? imageFile(Product product) {
    final ref = product.image;
    // Confinement (§7): only our own layout resolves — a foreign file's ref
    // must never escape the pantry folder.
    if (ref == null ||
        !RegExp(r'^images/[A-Za-z0-9._-]+$').hasMatch(ref) ||
        ref.contains('..')) {
      return null;
    }
    return File('${root.path}/$ref');
  }
}
