// SAF document-tree impl of DiaryStore — saf_pantry_store.dart's discipline
// applied to the diary, minus images (a day file is JSON and nothing else).
// Layout: `diary/<YYYY-MM-DD>.json` inside the user-picked tree, so the diary
// lives and syncs beside the recipes and the pantry.
//
// ONE child-documents query per directory, held as an in-memory name→docId
// map; per-file lookups are banned (§4). A lost grant surfaces as
// GrantLostException for the re-pick flow, never a crash (§7).

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/diary.dart';
import 'diary_store.dart';
import 'saf_store.dart' show GrantLostException, StoreIoException;

class SafDiaryStore implements DiaryStore {
  SafDiaryStore({
    required this.treeUri,
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  /// Tree URI of the user-picked folder — diary is its 'diary/' subdir.
  final String treeUri;

  final MethodChannel channel;

  // Session index (D4: rescan per session, no persisted cache).
  String? _dirId;
  Map<String, String>? _files; // name -> docId inside diary/

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

  Future<void> _refresh() async {
    String? dirId;
    for (final row in await _listChildren(null)) {
      if (row['isDir'] == true && row['name'] == 'diary') {
        dirId = row['docId'] as String? ?? '';
      }
    }
    final files = <String, String>{};
    if (dirId != null) {
      for (final row in await _listChildren(dirId)) {
        if (row['isDir'] == true) continue;
        files[row['name'] as String? ?? ''] = row['docId'] as String? ?? '';
      }
    }
    _dirId = dirId;
    _files = files;
  }

  Future<Map<String, String>> _root() async {
    if (_files == null) await _refresh();
    return _files!;
  }

  Future<String> _ensureDir() async {
    if (_dirId != null) return _dirId!;
    await _root();
    return _dirId ??= await _invoke<String>(
        'createDir', {'treeUri': treeUri, 'name': 'diary'});
  }

  @override
  Future<DiaryDay> load(String date) async {
    if (!isDiaryDate(date)) return DiaryDay.empty(date);
    final docId = (await _root())['$date.json'];
    if (docId == null) return DiaryDay.empty(date);
    try {
      final bytes = await _invoke<Uint8List>(
          'readFile', {'treeUri': treeUri, 'docId': docId});
      final json = jsonDecode(utf8.decode(bytes, allowMalformed: true))
          as Map<String, dynamic>;
      if (diaryProblems(json).isNotEmpty) return DiaryDay.empty(date);
      return DiaryDay.fromJson(json);
    } on GrantLostException {
      rethrow;
    } catch (_) {
      return DiaryDay.empty(date); // corrupt file, never fatal (§7)
    }
  }

  @override
  Future<DiaryDay> save(DiaryDay day) async {
    if (!isDiaryDate(day.date)) {
      throw StateError('refusing to save diary day "${day.date}"');
    }
    final files = await _root();
    final name = '${day.date}.json';
    if (day.isEmpty) {
      // An emptied day loses its file, exactly like the local store.
      final docId = files[name];
      if (docId != null) {
        try {
          await _invoke<bool>(
              'deleteFile', {'treeUri': treeUri, 'docId': docId});
        } on PlatformException {
          // A delete we couldn't do is not worth failing the edit over; the
          // next save rewrites the same docId anyway.
        }
        files.remove(name);
      }
      return day;
    }
    final blocking = diaryProblems(day.toJson());
    if (blocking.isNotEmpty) {
      throw StateError('refusing to save invalid day: ${blocking.join('; ')}');
    }
    try {
      final dirId = await _ensureDir();
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
            const JsonEncoder.withIndent('  ').convert(day.toJson()))),
      });
      return day;
    } on PlatformException catch (e) {
      throw StoreIoException('save failed: ${e.message ?? e.code}');
    }
  }

  @override
  Future<List<String>> loggedDates() async {
    await _refresh();
    final dates = <String>[];
    for (final name in _files!.keys) {
      if (!name.endsWith('.json')) continue;
      final stem = name.substring(0, name.length - '.json'.length);
      if (isDiaryDate(stem)) dates.add(stem);
    }
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) =>
      collectRecentEntries(this, days: days, limit: limit);

  /// The directory listing is a session cache; the diary can change under us
  /// when the connector pulls a day down from Drive.
  void invalidate() {
    _files = null;
    _dirId = null;
  }
}
