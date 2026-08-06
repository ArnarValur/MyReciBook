// Library state (D3: ChangeNotifier + Provider, nothing more).

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/recipe_store.dart';
import '../domain/recipe.dart';

class LibraryModel extends ChangeNotifier {
  LibraryModel(this._store);

  final RecipeStore _store;

  List<Recipe> _recipes = const [];
  int _skipped = 0;
  bool _loading = false;

  List<Recipe> get recipes => _recipes;
  int get skipped => _skipped;
  bool get loading => _loading;

  /// D4: rescan the folder each session — no persisted cache.
  Future<void> rescan() async {
    _loading = true;
    notifyListeners();
    final result = await _store.listAll();
    _recipes = result.recipes;
    _skipped = result.skipped;
    _loading = false;
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _store.delete(id);
    await rescan();
  }

  /// Also used for post-save notes edits with empty [cachedImages], which
  /// keeps original_images (D6).
  Future<Recipe> saveImported(Recipe recipe, List<File> cachedImages) async {
    final saved = await _store.save(recipe, cachedImages);
    await rescan();
    return saved;
  }

  /// Cover = the recipe's first original screenshot (tier-1 zero-effort cover).
  File? coverFor(Recipe recipe) {
    final refs = recipe.source.originalImages ?? const [];
    return refs.isEmpty ? null : _store.resolveImage(refs.first);
  }

  File? imageFor(String ref) => _store.resolveImage(ref);
}
