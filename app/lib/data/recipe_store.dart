// Storage (architecture §4): one <id>.json per recipe + images/<id>-<n>.jpg,
// in a folder the user owns. This local-folder impl is the engine slice; the
// SAF document-tree impl replaces the root lookup, not the layout (budgeted
// separately — architecture §8).

import 'dart:convert';
import 'dart:io';

import '../domain/recipe.dart';
import '../domain/validate.dart';

class StoreResult {
  final List<Recipe> recipes;

  /// Foreign or unparseable files skipped during scan — counted, never fatal
  /// (architecture §7: a hostile folder must not take down the list screen).
  final int skipped;

  const StoreResult(this.recipes, this.skipped);
}

abstract class RecipeStore {
  Future<StoreResult> listAll();
  Future<Recipe?> load(String id);

  /// Validates, writes JSON, copies [cachedImages] to `images/<id>-<n>.jpg`.
  /// Throws [StateError] when the file has save-blocking validation problems.
  Future<Recipe> save(Recipe recipe, List<File> cachedImages);
  Future<void> delete(String id);

  /// Resolves a stored `images/…` reference (or a pre-save absolute path) to a
  /// readable file; null when the reference is unsafe (§7 confinement).
  Future<File?> imageFile(String ref);

  // Arch §7 hostile-folder safety: a foreign JSON's id/original_images must
  // never resolve outside the store. Ids are uuid filename stems; images stay
  // under images/. Shared by every RecipeStore impl.
  static bool safeId(String id) =>
      id.isNotEmpty &&
      !id.contains('/') &&
      !id.contains('\\') &&
      !id.contains('..');

  static bool safeImageRef(String rel) =>
      rel.startsWith('images/') && safeId(rel.substring('images/'.length));
}

class LocalFolderStore implements RecipeStore {
  final Directory root;

  LocalFolderStore(this.root);

  Directory get _imagesDir => Directory('${root.path}/images');

  static bool _safeId(String id) => RecipeStore.safeId(id);

  static bool _safeImagePath(String rel) => RecipeStore.safeImageRef(rel);

  @override
  Future<StoreResult> listAll() async {
    if (!await root.exists()) return const StoreResult([], 0);
    final recipes = <Recipe>[];
    var skipped = 0;
    await for (final entity in root.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
        if (fileProblems(json).where(isSaveBlocking).isNotEmpty) {
          skipped++;
          continue;
        }
        recipes.add(Recipe.fromJson(json));
      } catch (_) {
        skipped++;
      }
    }
    recipes.sort((a, b) => (b.source.importedAt ?? '').compareTo(a.source.importedAt ?? ''));
    return StoreResult(recipes, skipped);
  }

  @override
  Future<Recipe?> load(String id) async {
    if (!_safeId(id)) return null;
    final file = File('${root.path}/$id.json');
    if (!await file.exists()) return null;
    try {
      return Recipe.fromJson(
          jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } catch (_) {
      return null; // corrupt file: same never-fatal stance as listAll (§7)
    }
  }

  @override
  Future<Recipe> save(Recipe recipe, List<File> cachedImages) async {
    final blocking = fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (!_safeId(recipe.id)) blocking.add('unsafe id "${recipe.id}"');
    if (blocking.isNotEmpty) {
      throw StateError('refusing to save invalid recipe: ${blocking.join('; ')}');
    }
    await root.create(recursive: true);

    final imagePaths = <String>[];
    if (cachedImages.isNotEmpty) {
      await _imagesDir.create(recursive: true);
      for (var n = 0; n < cachedImages.length; n++) {
        final ext = cachedImages[n].path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        final rel = 'images/${recipe.id}-${n + 1}.$ext';
        await cachedImages[n].copy('${root.path}/$rel');
        imagePaths.add(rel);
      }
    }

    final complete = Recipe.fromJson(recipe.toJson()
      ..['source'] = (RecipeSource(
        type: recipe.source.type,
        importedAt: recipe.source.importedAt,
        originalImages: imagePaths.isEmpty ? recipe.source.originalImages : imagePaths,
        appHint: recipe.source.appHint,
      ).toJson()));

    final file = File('${root.path}/${recipe.id}.json');
    await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(complete.toJson()));
    return complete;
  }

  @override
  Future<File?> imageFile(String ref) async {
    if (_safeImagePath(ref)) return File('${root.path}/$ref');
    final f = File(ref);
    return f.isAbsolute ? f : null;
  }

  @override
  Future<void> delete(String id) async {
    if (!_safeId(id)) return;
    final file = File('${root.path}/$id.json');
    List<String>? images;
    if (await file.exists()) {
      try {
        images = Recipe.fromJson(
                jsonDecode(await file.readAsString()) as Map<String, dynamic>)
            .source
            .originalImages;
      } catch (_) {} // still delete the JSON below
      await file.delete();
    }
    for (final rel in images ?? const <String>[]) {
      if (!_safeImagePath(rel)) continue;
      final img = File('${root.path}/$rel');
      if (await img.exists()) await img.delete();
    }
  }
}
