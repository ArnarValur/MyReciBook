// Batch import queue (design 2b/3b) — SESSION state only (D5): the queue dies
// with the app, no persisted inbox; the cached picks (and a held extraction)
// are the retry artifact. Design intent (1a): "Batch of 20 ≠ 20 review
// screens" — high-confidence items save straight to the cookbook with their
// needs_review flags kept in the file (the review-later hook); only failures,
// low confidence and not-a-recipe skips demand attention.
//
// The worker is strictly SEQUENTIAL — one extractContent at a time (technical
// rule 4: free-tier 503s are transient and retried inside the extractor;
// never parallel-hammer the API).

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../domain/extractor.dart';
import '../domain/recipe.dart';
import '../domain/validate.dart';

enum BatchItemState { waiting, extracting, saved, needsReview, failed, skipped }

class BatchItem {
  BatchItem(this.id, this.images);

  final String id;

  /// Cached picks — the retry artifact (D5). They stay on disk with the app.
  final List<File> images;

  BatchItemState state = BatchItemState.waiting;

  /// Held extraction: set on every non-transport outcome. For [needsReview]
  /// it feeds the prefilled review screen; for a failed *save* it lets retry
  /// skip the AI call entirely.
  Map<String, dynamic>? content;

  /// The recipe as saved (auto or via review).
  Recipe? recipe;

  /// Failure caption for the card; null unless [state] is failed.
  String? error;

  /// Saved through review-now rather than auto-saved.
  bool reviewed = false;

  String get title {
    final t = (content?['title'] as String?)?.trim();
    return (t == null || t.isEmpty) ? 'Screenshot' : t;
  }

  /// Distinct flagged lines — the 3b "1 line needs your eyes" caption. Counts
  /// the same lines the review screen will flag: confidence under the bar or
  /// a needs_review path.
  int get flaggedLines {
    final c = content;
    if (c == null) return 0;
    final ex = c['extraction'];
    final nr = ex is Map
        ? [for (final p in (ex['needs_review'] as List? ?? const [])) '$p']
        : const <String>[];
    bool low(Object? line) =>
        line is Map &&
        ((line['confidence'] as num?)?.toDouble() ?? 1.0) <
            BatchModel.reviewBar;
    var n = 0;
    final ings = c['ingredients'] as List? ?? const [];
    for (var i = 0; i < ings.length; i++) {
      if (low(ings[i]) || nr.any((p) => p.startsWith('ingredients[$i]'))) n++;
    }
    final steps = c['steps'] as List? ?? const [];
    for (var i = 0; i < steps.length; i++) {
      if (low(steps[i]) || nr.any((p) => p.startsWith('steps[$i]'))) n++;
    }
    if (nr.contains('title')) n++;
    return n;
  }
}

class BatchModel extends ChangeNotifier {
  BatchModel({required this.extractor, required this.save});

  final Extractor extractor;

  /// The LibraryModel.saveImported seam — grocery/storage integration rides
  /// its existing onChanged; the batch never touches those layers directly.
  final Future<Recipe> Function(Recipe recipe, List<File> cachedImages) save;

  /// Auto-save bar over extraction.overall_confidence — the same 0.8 the
  /// review screen uses per line.
  static const double reviewBar = 0.8;

  static const _uuid = Uuid();

  final List<BatchItem> _items = [];
  bool _working = false;
  bool _disposed = false;
  Completer<void>? _idle;

  List<BatchItem> get items => List.unmodifiable(_items);
  bool get working => _working;

  int _count(BatchItemState s) => _items.where((i) => i.state == s).length;

  /// Still moving: the header shows "Rescuing…" while this is nonzero.
  int get remaining =>
      _count(BatchItemState.waiting) + _count(BatchItemState.extracting);

  /// Items demanding the user's eyes — the drawer badge (needsReview + failed).
  int get attention =>
      _count(BatchItemState.needsReview) + _count(BatchItemState.failed);

  int get savedCount => _count(BatchItemState.saved);
  int get skippedCount => _count(BatchItemState.skipped);

  /// Completes when the worker drains; already-complete when idle.
  Future<void> get whenIdle =>
      _working ? (_idle ??= Completer<void>()).future : Future.value();

  /// Enqueue one item per group (batch mode: one group per screenshot). A new
  /// batch sweeps finished noise first; items still needing attention stay.
  void addAll(List<List<File>> groups) {
    _removeFinished();
    for (final g in groups) {
      if (g.isNotEmpty) _items.add(BatchItem(_uuid.v4(), List.of(g)));
    }
    notifyListeners();
    _pump();
  }

  /// Failed → back in line. A held extraction (failed at the *save* step) is
  /// reused — no second AI call; a transport failure re-extracts.
  void retry(BatchItem item) {
    if (item.state != BatchItemState.failed) return;
    item.state = BatchItemState.waiting;
    item.error = null;
    notifyListeners();
    _pump();
  }

  /// Review-now hand-off completed: the review screen saved [saved].
  void markReviewed(BatchItem item, Recipe saved) {
    item.recipe = saved;
    item.reviewed = true;
    item.state = BatchItemState.saved;
    notifyListeners();
  }

  void removeItem(BatchItem item) {
    if (item.state == BatchItemState.extracting) return; // mid-flight
    _items.remove(item);
    notifyListeners();
  }

  /// Drops saved + skipped; needsReview and failed stay until acted on.
  void clearFinished() {
    _removeFinished();
    notifyListeners();
  }

  void _removeFinished() => _items.removeWhere((i) =>
      i.state == BatchItemState.saved || i.state == BatchItemState.skipped);

  void _pump() {
    if (_working) return;
    _working = true;
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      while (true) {
        BatchItem? next;
        for (final i in _items) {
          if (i.state == BatchItemState.waiting) {
            next = i;
            break;
          }
        }
        if (next == null) break;
        next.state = BatchItemState.extracting;
        _notify();
        await _process(next);
        _notify();
      }
    } finally {
      _working = false;
      _idle?.complete();
      _idle = null;
      _notify();
    }
  }

  Future<void> _process(BatchItem item) async {
    var content = item.content;
    if (content == null) {
      try {
        content = await extractor.extractContent(item.images);
      } on ExtractionException catch (e) {
        item.state = BatchItemState.failed;
        item.error = _failCopy(e);
        return;
      } catch (_) {
        item.state = BatchItemState.failed;
        item.error = 'failed · tap retry';
        return;
      }
    }
    item.content = content;

    // Not-a-recipe: the prompt forbids inventing (rule 1), so a non-recipe
    // comes back as an empty shell — under 2 ingredients AND no steps means
    // there was nothing to rescue. Honest skip (2a), never junk in the book.
    final ings = content['ingredients'] as List? ?? const [];
    final steps = content['steps'] as List? ?? const [];
    if (ings.length < 2 && steps.isEmpty) {
      item.state = BatchItemState.skipped;
      return;
    }

    final ex = content['extraction'];
    final overall =
        ex is Map ? (ex['overall_confidence'] as num?)?.toDouble() : null;

    final recipe = Recipe.assemble(
      id: _uuid.v4(),
      content: content,
      originalImages: [for (final f in item.images) f.path],
      importedAt: DateTime.now(),
      extractorModel: extractor.modelName,
      extractorMode: extractor.mode,
    );

    // Hold for the user (§6.3 suggest-and-confirm): save-blocking problems,
    // an overall confidence under the bar (or missing — unknown is not high),
    // or empty steps. Per-line needs_review flags alone do NOT hold — they
    // auto-save into the file as the review-later hook.
    final blocking = fileProblems(recipe.toJson()).where(isSaveBlocking);
    if (blocking.isNotEmpty ||
        steps.isEmpty ||
        overall == null ||
        overall < reviewBar) {
      item.state = BatchItemState.needsReview;
      return;
    }

    try {
      item.recipe = await save(recipe, item.images);
      item.state = BatchItemState.saved;
    } catch (_) {
      // GrantLost / SAF_IO / StateError: the extraction is held, so retry
      // goes straight back to the save — no AI call burned.
      item.state = BatchItemState.failed;
      item.error = "couldn't save to your folder · tap retry";
    }
  }

  static String _failCopy(ExtractionException e) {
    if (e.httpStatus == 429) return 'rate-limited · retry in a minute';
    if (e.message.startsWith('offline')) return 'offline · retry when connected';
    return 'failed · tap retry';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
