// tags.json at the root of the user's folder — the DECORATION half of tags.
// Membership rides the recipe files; this only says what a tag looks like.
//
// Same discipline as saf_diary_store: one child-documents query per session,
// a lost grant surfaces as GrantLostException for the re-pick flow, and a
// corrupt file reads as empty rather than crashing. Losing this file costs
// icons and colours, never a tag — the library's own strings are the truth.

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/recipe_tag.dart';
import 'saf_store.dart' show GrantLostException;

const String kTagsFileName = 'tags.json';

abstract class TagStore {
  /// Never throws on a missing or corrupt file — empty is a valid answer.
  Future<List<RecipeTag>> load();

  /// Whole-list write: the file is small, order is meaningful, and a
  /// per-entry merge would need a second identity we deliberately do not have.
  Future<void> save(List<RecipeTag> tags);
}

/// The test seam and the no-folder fallback: holds the list in memory.
class MemoryTagStore implements TagStore {
  MemoryTagStore([this._tags = const []]);

  List<RecipeTag> _tags;

  @override
  Future<List<RecipeTag>> load() async => List.of(_tags);

  @override
  Future<void> save(List<RecipeTag> tags) async => _tags = List.of(tags);
}

class SafTagStore implements TagStore {
  SafTagStore({
    required this.treeUri,
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  final String treeUri;
  final MethodChannel channel;

  // DocumentsContract.getTreeDocumentId — the tree URI's second path segment.
  // Root createFile needs the root's own doc id, not null (saf_store.dart).
  String get _rootDocId {
    final segs = Uri.parse(treeUri).pathSegments;
    return segs.length > 1 ? segs[1] : '';
  }

  /// Session index of the tree root (D4: rescan per session, no cache on disk).
  Map<String, String>? _root;

  Future<T> _invoke<T>(String method, Map<String, Object?> args) async {
    try {
      return await channel.invokeMethod<T>(method, args) as T;
    } on PlatformException catch (e) {
      if (e.code == 'GRANT_LOST') {
        throw GrantLostException(e.message ?? 'grant lost');
      }
      rethrow;
    }
  }

  Future<Map<String, String>> _rootFiles() async {
    if (_root != null) return _root!;
    final files = <String, String>{};
    final rows = await _invoke<List<dynamic>>(
        'listChildren', {'treeUri': treeUri, 'parentDocId': null});
    for (final r in rows) {
      final row = (r as Map).cast<String, Object?>();
      if (row['isDir'] == true) continue;
      files[row['name'] as String? ?? ''] = row['docId'] as String? ?? '';
    }
    return _root = files;
  }

  @override
  Future<List<RecipeTag>> load() async {
    final docId = (await _rootFiles())[kTagsFileName];
    if (docId == null) return const [];
    try {
      final bytes =
          await _invoke<Uint8List>('readFile', {'treeUri': treeUri, 'docId': docId});
      final json = jsonDecode(utf8.decode(bytes, allowMalformed: true));
      final list = json is Map<String, dynamic> ? json['tags'] : json;
      if (list is! List) return const [];
      final out = <RecipeTag>[];
      final seen = <String>{};
      for (final entry in list) {
        if (entry is! Map) continue;
        final tag = RecipeTag.fromJson(entry.cast<String, dynamic>());
        // A duplicate name is the same tag twice: keep the first, drop the
        // rest, so the list can never disagree with itself.
        if (tag == null || !seen.add(RecipeTag.canonical(tag.name))) continue;
        out.add(tag);
      }
      return out;
    } on GrantLostException {
      rethrow;
    } catch (_) {
      return const []; // corrupt file: plain tags, never a crash (§7)
    }
  }

  @override
  Future<void> save(List<RecipeTag> tags) async {
    final files = await _rootFiles();
    // Wrapped in an object rather than a bare array: it leaves room to add a
    // schemaVersion later without rewriting everyone's file.
    final body = const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'tags': [for (final t in tags) t.toJson()],
    });
    // Existing docId first — never let SAF auto-rename create "tags (1).json".
    final docId = files[kTagsFileName] ??
        await _invoke<String>('createFile', {
          'treeUri': treeUri,
          'parentDocId': _rootDocId,
          'name': kTagsFileName,
          'mime': 'application/json',
        });
    files[kTagsFileName] = docId;
    await _invoke<void>('writeFile', {
      'treeUri': treeUri,
      'docId': docId,
      'bytes': Uint8List.fromList(utf8.encode(body)),
    });
  }
}
