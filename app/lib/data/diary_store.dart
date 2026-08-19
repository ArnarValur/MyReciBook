// Storage (architecture §4 applied to the diary): one <YYYY-MM-DD>.json per
// logged day in a diary folder the user owns, beside their recipes and
// pantry. Same discipline as the pantry store — atomic writes, confined
// stems, a hostile folder is counted and skipped, never fatal (§7).
//
// A day with nothing in it has NO file. Opening the app on a new morning must
// not litter the user's Drive with 365 empty objects a year, and "which days
// did I log?" is then just a directory listing.

import 'dart:convert';
import 'dart:io';

import '../domain/diary.dart';
import 'atomic_file.dart';

abstract class DiaryStore {
  /// The day as stored, or an empty day when nothing was logged. Never null:
  /// every date in the calendar is a valid thing to open.
  Future<DiaryDay> load(String date);

  /// Validates and writes `<date>.json`. An empty day DELETES its file
  /// instead of writing `{"meals":[]}` — removing your last entry should
  /// leave no trace. Throws [StateError] on save-blocking problems.
  Future<DiaryDay> save(DiaryDay day);

  /// Dates that have a file, newest first.
  Future<List<String>> loggedDates();

  /// Foods logged recently, newest first, one row per distinct food — MFP's
  /// "Recent" tab. [days] bounds how far back it reads so the picker never
  /// walks a two-year folder.
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50});
}

class LocalDiaryStore implements DiaryStore {
  final Directory root;

  LocalDiaryStore(this.root);

  File _file(String date) => File('${root.path}/$date.json');

  @override
  Future<DiaryDay> load(String date) async {
    if (!isDiaryDate(date)) return DiaryDay.empty(date);
    final file = _file(date);
    if (!await file.exists()) return DiaryDay.empty(date);
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (diaryProblems(json).isNotEmpty) return DiaryDay.empty(date);
      return DiaryDay.fromJson(json);
    } catch (_) {
      // Corrupt file: the same never-fatal stance as the pantry (§7). The
      // day reads empty; the bad file is left on disk untouched rather than
      // silently overwritten — the user's bytes are theirs.
      return DiaryDay.empty(date);
    }
  }

  @override
  Future<DiaryDay> save(DiaryDay day) async {
    if (!isDiaryDate(day.date)) {
      throw StateError('refusing to save diary day "${day.date}"');
    }
    if (day.isEmpty) {
      await _delete(day.date);
      return day;
    }
    final blocking = diaryProblems(day.toJson());
    if (blocking.isNotEmpty) {
      throw StateError('refusing to save invalid day: ${blocking.join('; ')}');
    }
    await root.create(recursive: true);
    await writeStringAtomic(_file(day.date),
        const JsonEncoder.withIndent('  ').convert(day.toJson()));
    return day;
  }

  Future<void> _delete(String date) async {
    final file = _file(date);
    if (await file.exists()) await file.delete();
    final tmp = File('${file.path}.tmp');
    if (await tmp.exists()) await tmp.delete();
  }

  @override
  Future<List<String>> loggedDates() async {
    if (!await root.exists()) return [];
    final dates = <String>[];
    await for (final entity in root.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final name = entity.uri.pathSegments.last;
      final stem = name.substring(0, name.length - '.json'.length);
      if (isDiaryDate(stem)) dates.add(stem);
    }
    dates.sort((a, b) => b.compareTo(a)); // ISO dates sort as strings
    return dates;
  }

  @override
  Future<List<DiaryEntry>> recentEntries({int days = 14, int limit = 50}) =>
      collectRecentEntries(this, days: days, limit: limit);
}

/// Shared by every DiaryStore impl: walk the newest [days] files and keep the
/// first sighting of each distinct food. Deduped by what the user would call
/// the same thing — the product/recipe it came from, else its name.
Future<List<DiaryEntry>> collectRecentEntries(
  DiaryStore store, {
  int days = 14,
  int limit = 50,
}) async {
  final dates = await store.loggedDates();
  final seen = <String>{};
  final out = <DiaryEntry>[];
  for (final date in dates.take(days)) {
    final day = await store.load(date);
    // Within a day, newest meal last — walk backwards so "recent" means it.
    for (final meal in day.meals.reversed) {
      for (final entry in meal.entries.reversed) {
        final key = '${entry.source}:${entry.ref ?? entry.name.toLowerCase()}';
        if (!seen.add(key)) continue;
        out.add(entry);
        if (out.length >= limit) return out;
      }
    }
  }
  return out;
}

/// A logged food promoted back into something loggable again — MFP's "tap a
/// recent, it logs with the same serving". Keeps the snapshot: re-logging
/// yesterday's oats uses yesterday's numbers, not a fresh product read.
DiaryEntry relog(DiaryEntry entry,
        {required String id, double? quantity, String? loggedAt}) =>
    DiaryEntry(
      id: id,
      name: entry.name,
      brand: entry.brand,
      source: entry.source,
      ref: entry.ref,
      servingLabel: entry.servingLabel,
      servingGrams: entry.servingGrams,
      quantity: quantity ?? entry.quantity,
      perServing: entry.perServing,
      loggedAt: loggedAt,
    );
