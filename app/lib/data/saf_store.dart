// SAF document-tree impl of RecipeStore (architecture §4): same layout as
// LocalFolderStore — <id>.json at the tree root, images/<id>-<n>.<ext> in an
// images/ subdir — the root lookup goes through the platform bridge instead.
// Scan strategy: ONE child-documents query per directory, held as an
// in-memory name→docId map; per-file lookups are banned (§4). Lost grant
// surfaces as GrantLostException for the re-pick flow, never a crash (§7).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/recipe.dart';
import '../domain/validate.dart';
import 'recipe_store.dart';

/// Transient SAF write failure (SAF_IO) — may succeed on retry. Subtype of
/// [StateError] so save-failed UI paths keep working; migration counts these
/// separately so the one-shot flag is never set over a stranded recipe.
class StoreIoException extends StateError {
  StoreIoException(super.message);
}

/// SAF grant revoked or tree gone — branch to the re-pick flow (§7).
class GrantLostException implements Exception {
  final String message;

  GrantLostException([this.message = 'SAF grant lost']);

  @override
  String toString() => 'GrantLostException: $message';
}

class SafFolderStore implements RecipeStore {
  SafFolderStore({
    required this.treeUri,
    required this.imageCache,
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  /// Tree URI of the user-picked folder (Uri.toString of the picked tree).
  final String treeUri;

  /// App-private dir where SAF image bytes are hydrated so Image.file and the
  /// extractor get a real File; keyed by ref basename, disposable.
  final Directory imageCache;

  final MethodChannel channel;

  // Session index (D4: rescan per session, no persisted cache). Root refreshed
  // on every listAll; images/ listed lazily on first need.
  Map<String, String>? _rootFiles; // name -> docId, files at tree root
  String? _imagesDirId;
  Map<String, String>? _imageFiles; // name -> docId, inside images/

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

  Future<void> _refreshRoot() async {
    final rows = await _listChildren(null);
    final files = <String, String>{};
    String? imagesDirId;
    for (final row in rows) {
      final name = row['name'] as String? ?? '';
      final docId = row['docId'] as String? ?? '';
      if (row['isDir'] == true) {
        if (name == 'images') imagesDirId = docId;
      } else {
        files[name] = docId;
      }
    }
    _rootFiles = files;
    _imagesDirId = imagesDirId;
    _imageFiles = null;
  }

  Future<Map<String, String>> _root() async {
    if (_rootFiles == null) await _refreshRoot();
    return _rootFiles!;
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

  @override
  Future<StoreResult> listAll() async {
    await _refreshRoot();
    final recipes = <Recipe>[];
    var skipped = 0;
    for (final entry in _rootFiles!.entries) {
      if (!entry.key.endsWith('.json')) continue;
      try {
        final bytes = await _invoke<Uint8List>(
            'readFile', {'treeUri': treeUri, 'docId': entry.value});
        final json = jsonDecode(utf8.decode(bytes, allowMalformed: true))
            as Map<String, dynamic>;
        if (fileProblems(json).where(isSaveBlocking).isNotEmpty) {
          skipped++;
          continue;
        }
        recipes.add(Recipe.fromJson(json));
      } on GrantLostException {
        rethrow;
      } catch (_) {
        skipped++; // foreign/corrupt/unreadable: counted, never fatal (§7)
      }
    }
    recipes.sort((a, b) =>
        (b.source.importedAt ?? '').compareTo(a.source.importedAt ?? ''));
    return StoreResult(recipes, skipped);
  }

  @override
  Future<Recipe?> load(String id) async {
    if (!RecipeStore.safeId(id)) return null;
    final docId = (await _root())['$id.json'];
    if (docId == null) return null;
    try {
      final bytes = await _invoke<Uint8List>(
          'readFile', {'treeUri': treeUri, 'docId': docId});
      return Recipe.fromJson(jsonDecode(utf8.decode(bytes, allowMalformed: true))
          as Map<String, dynamic>);
    } on GrantLostException {
      rethrow;
    } catch (_) {
      return null; // corrupt file: same never-fatal stance as listAll (§7)
    }
  }

  @override
  Future<Recipe> save(Recipe recipe, List<File> cachedImages,
      {File? coverImage}) async {
    final blocking = fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (!RecipeStore.safeId(recipe.id)) blocking.add('unsafe id "${recipe.id}"');
    if (blocking.isNotEmpty) {
      throw StateError('refusing to save invalid recipe: ${blocking.join('; ')}');
    }

    try {
      final rootFiles = await _root();

      // Shared by the originals and the cover: both are app-owned files under
      // images/, written through the same create-or-reuse dance.
      Future<String> writeImage(String name, File src) async {
        if (_imagesDirId == null) {
          _imagesDirId = await _invoke<String>(
              'createDir', {'treeUri': treeUri, 'name': 'images'});
          _imageFiles = {};
        }
        final images = await _images();
        // Existing docId first — never let SAF auto-rename create "x (1)".
        final docId = images[name] ??
            await _invoke<String>('createFile', {
              'treeUri': treeUri,
              'parentDocId': _imagesDirId,
              'name': name,
              'mime':
                  name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg',
            });
        images[name] = docId;
        await _invoke<void>('writeFile', {
          'treeUri': treeUri,
          'docId': docId,
          'bytes': await src.readAsBytes(),
        });
        // Stale hydrated copy must not shadow the new bytes.
        final cached = File('${imageCache.path}/$name');
        if (await cached.exists()) await cached.delete();
        return 'images/$name';
      }

      final imagePaths = <String>[];
      for (var n = 0; n < cachedImages.length; n++) {
        final ext =
            cachedImages[n].path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        imagePaths
            .add(await writeImage('${recipe.id}-${n + 1}.$ext', cachedImages[n]));
      }

      Future<void> dropCoverFile(String name) async {
        final images = await _images();
        final staleDocId = images[name];
        if (staleDocId != null) {
          await _invoke<bool>(
              'deleteFile', {'treeUri': treeUri, 'docId': staleDocId});
          images.remove(name);
        }
        final cached = File('${imageCache.path}/$name');
        if (await cached.exists()) await cached.delete();
      }

      String? coverRef = recipe.cover;
      if (coverImage != null) {
        final ext = coverImage.path.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        coverRef = await writeImage('${recipe.id}-cover.$ext', coverImage);
        // A cover swapped jpg↔png would otherwise leave the old file behind,
        // syncing forever with nothing pointing at it.
        await dropCoverFile('${recipe.id}-cover.${ext == 'png' ? 'jpg' : 'png'}');
      } else if (coverRef == null) {
        // "Remove cover" — take the bytes with it.
        await dropCoverFile('${recipe.id}-cover.jpg');
        await dropCoverFile('${recipe.id}-cover.png');
      }

      final complete = Recipe.fromJson(recipe.toJson()
        ..['source'] = (RecipeSource(
          type: recipe.source.type,
          importedAt: recipe.source.importedAt,
          originalImages:
              imagePaths.isEmpty ? recipe.source.originalImages : imagePaths,
          url: recipe.source.url,
          appHint: recipe.source.appHint,
        ).toJson())
        ..['cover'] = coverRef
        ..removeWhere((k, v) => k == 'cover' && v == null));

      final jsonName = '${recipe.id}.json';
      final jsonDocId = rootFiles[jsonName] ??
          await _invoke<String>('createFile', {
            'treeUri': treeUri,
            'parentDocId': _rootDocId,
            'name': jsonName,
            'mime': 'application/json',
          });
      rootFiles[jsonName] = jsonDocId;
      await _invoke<void>('writeFile', {
        'treeUri': treeUri,
        'docId': jsonDocId,
        'bytes': Uint8List.fromList(utf8.encode(
            const JsonEncoder.withIndent('  ').convert(complete.toJson()))),
      });
      return complete;
    } on PlatformException catch (e) {
      // SAF_IO mid-save: surface as the same failure class the UI already shows.
      throw StoreIoException('save failed: ${e.message ?? e.code}');
    }
  }

  @override
  Future<File?> imageFile(String ref) async {
    if (RecipeStore.safeImageRef(ref)) {
      final name = ref.substring('images/'.length);
      final cached = File('${imageCache.path}/$name');
      if (await cached.exists()) return cached;
      final docId = (await _images())[name];
      if (docId == null) return null;
      try {
        final bytes = await _invoke<Uint8List>(
            'readFile', {'treeUri': treeUri, 'docId': docId});
        await imageCache.create(recursive: true);
        await cached.writeAsBytes(bytes);
        return cached;
      } on GrantLostException {
        rethrow;
      } catch (_) {
        return null; // unreadable image: placeholder, not a crash
      }
    }
    final f = File(ref);
    return f.isAbsolute ? f : null;
  }

  @override
  Future<void> delete(String id) async {
    if (!RecipeStore.safeId(id)) return;
    final rootFiles = await _root();
    final docId = rootFiles['$id.json'];
    final images = <String>[];
    if (docId != null) {
      try {
        final bytes = await _invoke<Uint8List>(
            'readFile', {'treeUri': treeUri, 'docId': docId});
        final recipe = Recipe.fromJson(
            jsonDecode(utf8.decode(bytes, allowMalformed: true))
                as Map<String, dynamic>);
        images.addAll(recipe.source.originalImages ?? const []);
        // A picked cover is the app's own file too — it must not outlive the
        // recipe. Screenshot covers are already in originalImages.
        if (recipe.cover != null) images.add(recipe.cover!);
      } on GrantLostException {
        rethrow;
      } catch (_) {} // still delete the JSON below
      await _invoke<bool>(
          'deleteFile', {'treeUri': treeUri, 'docId': docId});
      rootFiles.remove('$id.json');
    }
    for (final rel in images) {
      if (!RecipeStore.safeImageRef(rel)) continue;
      final name = rel.substring('images/'.length);
      try {
        final imageIndex = await _images();
        final imgDocId = imageIndex[name];
        if (imgDocId != null) {
          await _invoke<bool>(
              'deleteFile', {'treeUri': treeUri, 'docId': imgDocId});
          imageIndex.remove(name);
        }
      } on GrantLostException {
        rethrow;
      } on PlatformException {
        // images/ vanished externally: JSON is already gone, cleanup is
        // best-effort (§7) — the hydrated copy below still gets removed.
      }
      final cached = File('${imageCache.path}/$name');
      if (await cached.exists()) await cached.delete();
    }
  }
}
