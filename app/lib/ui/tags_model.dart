// The tag list, live. Owns tags.json through a TagStore, and owns the two
// operations that have to reach into the recipe files: rename and delete.
//
// The stance that shapes all of it: the RECIPE FILES are the truth about
// which tags exist. tags.json only says what they look like. So the model
// always offers two lists — the decorated tags it loaded, and the names it
// found in the library that nobody has decorated yet. Losing tags.json costs
// icons and colours; it never loses a tag.

import 'package:flutter/foundation.dart';

import '../data/tag_store.dart';
import '../domain/recipe.dart';
import '../domain/recipe_tag.dart';
import 'library_model.dart';

class TagsModel extends ChangeNotifier {
  TagsModel({required this.store, this.library});

  final TagStore store;

  /// Needed by rename and delete, which rewrite the recipes that carry the
  /// tag. Null (tests, and before a folder exists) makes both decoration-only.
  final LibraryModel? library;

  List<RecipeTag> _tags = const [];
  bool _loading = true;
  String? _error;

  /// Decorated tags, in the user's order.
  List<RecipeTag> get tags => _tags;
  bool get loading => _loading;

  /// Last write failure, for the screen to show rather than swallow.
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _tags = await store.load();
      _error = null;
    } catch (e) {
      // A store that cannot be read is empty decoration, not a dead screen.
      _tags = const [];
      _error = '$e';
    }
    _loading = false;
    notifyListeners();
  }

  /// Every tag string carried by any recipe in the library.
  Set<String> get namesInUse {
    final out = <String>{};
    for (final r in library?.recipes ?? const <Recipe>[]) {
      out.addAll(r.tags);
    }
    return out;
  }

  /// Names the library uses that tags.json says nothing about. These are real
  /// tags — a hand-edited file, a synced folder from another install, or a
  /// tags.json that went missing — so the UI offers to give them an outfit
  /// rather than pretending they do not exist.
  List<String> get undecoratedNames {
    final known = {for (final t in _tags) RecipeTag.canonical(t.name)};
    final out = [
      for (final n in namesInUse)
        if (!known.contains(RecipeTag.canonical(n))) n
    ];
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// How many recipes carry this tag.
  int usageOf(String name) {
    final key = RecipeTag.canonical(name);
    var n = 0;
    for (final r in library?.recipes ?? const <Recipe>[]) {
      if (r.tags.any((t) => RecipeTag.canonical(t) == key)) n++;
    }
    return n;
  }

  RecipeTag? byName(String name) {
    final key = RecipeTag.canonical(name);
    for (final t in _tags) {
      if (RecipeTag.canonical(t.name) == key) return t;
    }
    return null;
  }

  /// The chip to draw for a tag string: its decoration if it has one, a plain
  /// label-only tag if it does not. This is the "recipe files win" rule in one
  /// method, and every screen goes through it.
  RecipeTag chipFor(String name) => byName(name) ?? RecipeTag(name: name);

  bool nameTaken(String name, {String? except}) {
    final key = RecipeTag.canonical(name);
    final skip = except == null ? null : RecipeTag.canonical(except);
    return _tags.any(
        (t) => RecipeTag.canonical(t.name) == key && RecipeTag.canonical(t.name) != skip);
  }

  Future<bool> create(RecipeTag tag) async {
    if (!RecipeTag.isValidName(tag.name) || nameTaken(tag.name)) return false;
    _tags = [..._tags, tag];
    await _persist();
    return true;
  }

  /// Edit in place. A changed NAME rewrites every recipe that carries the old
  /// one — the name IS the identity, and the alternative (an opaque id in the
  /// user's own file) is what the bet forbids. Icon/colour changes touch
  /// nothing but tags.json.
  Future<bool> update(String oldName, RecipeTag next) async {
    if (!RecipeTag.isValidName(next.name)) return false;
    final i = _tags.indexWhere(
        (t) => RecipeTag.canonical(t.name) == RecipeTag.canonical(oldName));
    if (i < 0) return false;
    if (nameTaken(next.name, except: oldName)) return false;
    final renamed = RecipeTag.canonical(oldName) != RecipeTag.canonical(next.name);
    _tags = [..._tags]..[i] = next;
    await _persist();
    if (renamed) await _rewriteRecipes(oldName, next.name);
    return true;
  }

  /// Deleted means gone (Arnar 2026-08-27): the name comes off every recipe
  /// that carries it as well as out of tags.json. A filter for a tag nobody
  /// can see is a ghost.
  Future<void> delete(String name) async {
    _tags = [
      for (final t in _tags)
        if (RecipeTag.canonical(t.name) != RecipeTag.canonical(name)) t
    ];
    await _persist();
    await _rewriteRecipes(name, null);
  }

  /// [newIndex] is post-removal, as ReorderableListView.onReorderItem hands
  /// it over.
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _tags.length) return;
    final next = [..._tags];
    final tag = next.removeAt(oldIndex);
    next.insert(newIndex.clamp(0, next.length), tag);
    _tags = next;
    await _persist();
  }

  /// Put [name] on [recipe] or take it off. Returns the saved recipe so the
  /// caller can keep its own copy fresh.
  Future<Recipe> toggleOn(Recipe recipe, String name) async {
    final key = RecipeTag.canonical(name);
    final has = recipe.tags.any((t) => RecipeTag.canonical(t) == key);
    final tags = has
        ? [for (final t in recipe.tags) if (RecipeTag.canonical(t) != key) t]
        : [...recipe.tags, name];
    final saved = await library!.saveImported(
        recipe.copyWith(tags: tags), const []);
    notifyListeners();
    return saved;
  }

  /// Rename ([to] non-null) or strip ([to] null) across the library. Best
  /// effort per recipe: one file that refuses to save must not abandon the
  /// rest half-done, so failures are counted into [error] and the pass
  /// continues.
  Future<void> _rewriteRecipes(String from, String? to) async {
    final library = this.library;
    if (library == null) return;
    final key = RecipeTag.canonical(from);
    var failed = 0;
    for (final r in [...library.recipes]) {
      if (!r.tags.any((t) => RecipeTag.canonical(t) == key)) continue;
      final tags = <String>[];
      for (final t in r.tags) {
        if (RecipeTag.canonical(t) != key) {
          tags.add(t);
        } else if (to != null && !tags.any((x) => RecipeTag.canonical(x) == RecipeTag.canonical(to))) {
          tags.add(to);
        }
      }
      try {
        await library.saveImported(r.copyWith(tags: tags), const []);
      } catch (_) {
        failed++;
      }
    }
    if (failed > 0) {
      _error = to == null
          ? "Couldn't remove the tag from $failed recipe${failed == 1 ? '' : 's'}"
          : "Couldn't rename the tag on $failed recipe${failed == 1 ? '' : 's'}";
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    notifyListeners(); // optimistic: the list is already true in memory
    try {
      await store.save(_tags);
      _error = null;
    } catch (e) {
      _error = 'Tag decorations not saved: $e';
    }
    notifyListeners();
  }
}
