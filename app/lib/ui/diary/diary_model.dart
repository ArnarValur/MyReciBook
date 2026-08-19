// Diary view-model — PantryModel's stance applied to logging: pure op on the
// day → store persist → notify. A null store (test seam, or a build with no
// folder yet) degrades to in-memory state, never a crash.
//
// One day is loaded at a time. Walking to yesterday is a fetch, not a cache
// scan: a year of diary files must never be resident to draw one screen.

import 'package:flutter/foundation.dart';

import '../../data/app_settings.dart';
import '../../data/diary_store.dart';
import '../../domain/diary.dart';
import '../../domain/product.dart';

class DiaryModel extends ChangeNotifier {
  DiaryModel(
    this._store, {
    AppSettings? settings,
    DateTime Function()? clock,
  })  :
        // A private field can't be a named parameter, so the formal stays.
        // ignore: prefer_initializing_formals
        _settings = settings,
        _clock = clock ?? DateTime.now {
    _date = diaryDate(_clock());
    _day = DiaryDay.empty(_date);
  }

  final DiaryStore? _store;
  final AppSettings? _settings;
  final DateTime Function() _clock;

  late String _date;
  late DiaryDay _day;
  bool _loading = false;
  bool _loaded = false;

  /// Foods logged in the last fortnight, newest first — the picker's Recent
  /// list. Loaded lazily: opening the diary must not read fourteen files.
  List<DiaryEntry> _recents = const [];
  bool _recentsLoaded = false;

  String get date => _date;
  DiaryDay get day => _day;
  bool get loading => _loading;
  bool get loaded => _loaded;
  List<DiaryEntry> get recents => _recents;

  /// True when [date] is the real today — the day strip's "Today" label and
  /// the forward-arrow stop both hang off this.
  bool get isToday => _date == diaryDate(_clock());

  /// The user's meal headings, or MFP's four when they've never said.
  List<String> get mealNames {
    final configured = _settings?.mealNames ?? const <String>[];
    return configured.isEmpty ? defaultMealNames : configured;
  }

  /// Headings to draw: the configured ones, plus any name this day was
  /// actually logged under. Renaming a meal must never hide yesterday's food.
  List<String> get visibleMealNames {
    final names = [...mealNames];
    for (final meal in _day.meals) {
      if (!names.contains(meal.name)) names.add(meal.name);
    }
    return names;
  }

  double? get calorieGoal => _settings?.calorieGoal;
  double? macroGoal(String key) => _settings?.macroGoal(key);

  Nutriments get total => _day.total;

  /// Goal − eaten. Null when no goal is set: the diary shows what you ate and
  /// says the goal is unset, rather than inventing 2000.
  double? get caloriesLeft {
    final goal = calorieGoal;
    if (goal == null) return null;
    return goal - (_day.total.kcal ?? 0);
  }

  Future<void> ensureLoaded() async {
    if (_loaded || _loading) return;
    await _load(_date);
  }

  /// Jump to a specific day. Out-of-range strings are ignored rather than
  /// throwing — the caller is a date picker, not a validator.
  Future<void> openDate(String date) async {
    if (!isDiaryDate(date) || date == _date) return;
    await _load(date);
  }

  Future<void> shiftDay(int days) =>
      openDate(diaryDate(DateTime.parse(_date).add(Duration(days: days))));

  Future<void> reload() => _load(_date, force: true);

  Future<void> _load(String date, {bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _date = date;
    notifyListeners();
    try {
      _day = await _store?.load(date) ?? DiaryDay.empty(date);
    } catch (_) {
      // A read that fails is an empty day on screen, never a broken tab (§7).
      _day = DiaryDay.empty(date);
    } finally {
      _loading = false;
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> ensureRecents() async {
    if (_recentsLoaded) return;
    _recentsLoaded = true;
    try {
      _recents = await _store?.recentEntries() ?? const [];
    } catch (_) {
      _recents = const [];
    }
    notifyListeners();
  }

  // --- goals ---

  Future<void> setCalorieGoal(double? kcal) async {
    await _settings?.setCalorieGoal(kcal);
    notifyListeners();
  }

  Future<void> setMacroGoal(String key, double? grams) async {
    await _settings?.setMacroGoal(key, grams);
    notifyListeners();
  }

  /// A one-line summary for the settings row — honest when nothing is set.
  String get goalSummary {
    final kcal = calorieGoal;
    if (kcal == null) return 'No daily goal yet';
    final macros = [
      for (final key in const ['fat', 'carbs', 'protein'])
        if (macroGoal(key) != null) '${macroGoal(key)!.round()} g'
    ];
    if (macros.isEmpty) return '${kcal.round()} kcal a day';
    return '${kcal.round()} kcal · ${macros.join(' / ')}';
  }

  // --- logging ---

  Future<DiaryEntry> logProduct(
    Product product,
    Serving serving, {
    required String meal,
    required double quantity,
  }) async {
    final entry = entryFromProduct(product, serving,
        quantity: quantity,
        id: newEntryId(),
        loggedAt: _clock().toUtc().toIso8601String());
    await _apply(_day.addEntry(meal, entry));
    return entry;
  }

  Future<DiaryEntry> logQuickAdd({
    required String meal,
    required double kcal,
    String name = 'Quick add',
    double? fat,
    double? carbs,
    double? protein,
  }) async {
    final entry = quickAddEntry(
      id: newEntryId(),
      kcal: kcal,
      name: name,
      fat: fat,
      carbs: carbs,
      protein: protein,
      loggedAt: _clock().toUtc().toIso8601String(),
    );
    await _apply(_day.addEntry(meal, entry));
    return entry;
  }

  /// Tap a Recent → it lands with the same serving it had last time. The
  /// snapshot travels with it; nothing is re-read from the pantry.
  Future<DiaryEntry> logAgain(DiaryEntry previous,
      {required String meal, double? quantity}) async {
    final entry = relog(previous,
        id: newEntryId(),
        quantity: quantity,
        loggedAt: _clock().toUtc().toIso8601String());
    await _apply(_day.addEntry(meal, entry));
    return entry;
  }

  Future<void> setQuantity(DiaryEntry entry, double quantity) =>
      _apply(_day.updateEntry(entry.copyWith(quantity: quantity)));

  Future<void> removeEntry(String entryId) =>
      _apply(_day.removeEntry(entryId));

  Future<void> moveEntry(String entryId, String toMeal) =>
      _apply(_day.moveEntry(entryId, toMeal));

  /// MFP's "copy to date": pull one meal from another day onto this one.
  Future<void> copyMealFrom(String fromDate, String mealName) async {
    final source = await _store?.load(fromDate);
    if (source == null) return;
    await _apply(_day.copyMealFrom(source, mealName, newIds: (_) => newEntryId()));
  }

  /// Persist, then notify. The in-memory day updates either way — a save
  /// that fails must not roll the screen back under the user's thumb; the
  /// store already refuses to write anything invalid.
  Future<void> _apply(DiaryDay next) async {
    _day = next;
    _recentsLoaded = false; // the recents list just changed
    notifyListeners();
    try {
      await _store?.save(next);
    } catch (_) {
      // Storage failures surface through the storage screen's own path; the
      // diary does not invent an error banner it can't act on.
    }
  }
}

/// Unique enough for one user's own files, and sortable by creation: the
/// microsecond clock in base 36, plus a per-process counter for the case of
/// two entries logged inside the same microsecond (a "log all" sweep).
int _seq = 0;
String newEntryId() {
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '$stamp-${(_seq++).toRadixString(36)}';
}
