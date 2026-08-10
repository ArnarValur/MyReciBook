// Library state (D3: ChangeNotifier + Provider, nothing more).

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/recipe_store.dart';
import '../data/saf_store.dart';
import '../domain/recipe.dart';

class LibraryModel extends ChangeNotifier {
  LibraryModel(this._store, {this.onGrantLost, this.onChanged});

  final RecipeStore _store;

  /// Grant lost during a store op → the boot gate swaps to re-pick (§7).
  final VoidCallback? onGrantLost;

  /// Fired after a mutation lands in the folder (save / delete succeeded).
  /// Main-level glue points it at StorageModel.syncSoon — the library never
  /// depends on the storage layer.
  final VoidCallback? onChanged;

  List<Recipe> _recipes = const [];
  int _skipped = 0;
  bool _loading = false;

  // Stable future per ref: FutureBuilder keeps its snapshot across rebuilds,
  // so covers don't flicker back to the placeholder.
  final Map<String, Future<File?>> _images = {};

  List<Recipe> get recipes => _recipes;
  int get skipped => _skipped;
  bool get loading => _loading;

  /// D4: rescan the folder each session — no persisted cache.
  Future<void> rescan() async {
    _loading = true;
    notifyListeners();
    var lost = false;
    try {
      final result = await _store.listAll();
      _recipes = result.recipes;
      _skipped = result.skipped;
    } on GrantLostException {
      lost = true;
    } catch (_) {
      // Transient SAF_IO: keep the last good list — never a stuck spinner (§7).
    } finally {
      _loading = false;
      notifyListeners();
    }
    if (lost) onGrantLost?.call();
  }

  Future<void> delete(String id) async {
    try {
      await _store.delete(id);
      onChanged?.call();
    } on GrantLostException {
      onGrantLost?.call();
      return;
    } catch (_) {
      // Best-effort (§7): the rescan below shows what actually happened.
    }
    await rescan();
  }

  /// Also used for post-save notes edits with empty [cachedImages], which
  /// keeps original_images (D6).
  ///
  /// GrantLost is deliberately NOT routed to [onGrantLost] here: swapping the
  /// boot gate would unmount the review/detail screen mid-save and destroy
  /// the in-flight edits. It propagates to the caller's save-failed path;
  /// the next list-level op (rescan/delete) re-enters the gate.
  Future<Recipe> saveImported(Recipe recipe, List<File> cachedImages,
      {File? coverImage}) async {
    final saved = await _store.save(recipe, cachedImages, coverImage: coverImage);
    onChanged?.call();
    for (final rel in [
      ...saved.source.originalImages ?? const <String>[],
      if (saved.cover != null) saved.cover!,
    ]) {
      _images.remove(rel); // new bytes must not resolve to a stale future
    }
    await rescan();
    return saved;
  }

  /// Cover = whatever the user picked, and nothing otherwise. Screenshots are
  /// provenance, not presentation: promoting one made ugly tiles, so an
  /// unpicked recipe gets the app's own drawn cover (Arnar 2026-08-10).
  Future<File?> coverFor(Recipe recipe) =>
      recipe.cover == null ? Future.value() : imageFor(recipe.cover!);

  /// Copies [photo] into the recipe's folder as its cover. Pass null for
  /// [photo] with [ref] set to promote one of the existing screenshots — no
  /// second copy of bytes that already live there.
  Future<Recipe> setCover(Recipe recipe, {File? photo, String? ref}) =>
      saveImported(recipe.copyWith(cover: ref), const [], coverImage: photo);

  Future<Recipe> clearCover(Recipe recipe) =>
      saveImported(recipe.copyWith(clearCover: true), const []);

  Future<File?> imageFor(String ref) =>
      _images.putIfAbsent(ref, () => _store.imageFile(ref));
}
