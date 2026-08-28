// Pantry view-model — GroceryModel's D3 stance applied to the food base:
// pure op → store persist → notify. A null store (test seam without pantry
// wiring) degrades to in-memory state — never crashes.
//
// The OFF lookup's three-way result surfaces verbatim as [PantryAddOutcome]:
// the UI must never read "OFF didn't answer" as "not in the database" — the
// shell-spike lesson from 2026-08-17, where throttling masqueraded as misses.

import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/off_client.dart';
import '../../data/product_store.dart';
import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../../domain/starter_foods.dart';

sealed class PantryAddOutcome {}

/// Saved (or re-saved: [wasKnown] = the barcode was already on the shelf, so
/// the scan refreshed one file instead of duplicating — store contract).
class PantryAdded extends PantryAddOutcome {
  PantryAdded(this.product, {required this.wasKnown});
  final Product product;
  final bool wasKnown;
}

/// Definitive: OFF answered and doesn't know this barcode. The label-photo
/// fallback (T5 capture, later) is the rescue path — not a retry.
class PantryNotFound extends PantryAddOutcome {
  PantryNotFound(this.barcode);
  final String barcode;
}

/// Transient: network/throttle. Retry is honest; saving nothing is correct.
class PantryUnavailable extends PantryAddOutcome {
  PantryUnavailable(this.message);
  final String message;
}

/// What a bulk re-fetch actually did. Products saved by an older build hold
/// only the seven label macros — Open Food Facts has vitamins and minerals
/// for most of them, and the only way to get those into a file already on
/// disk is to ask OFF again. Counted honestly, three ways, because "46
/// refreshed" would be a lie the moment the phone drops off wifi.
class PantryRefreshReport {
  const PantryRefreshReport({
    required this.updated,
    required this.unchanged,
    required this.missing,
    required this.failed,
  });

  /// OFF answered with different data and the file was rewritten.
  final int updated;

  /// OFF answered with exactly what the file already held.
  final int unchanged;

  /// OFF no longer knows this barcode — nothing to fetch, not an error.
  final int missing;

  /// Offline, timeout or throttled. The file is untouched; try again later.
  final int failed;

  int get total => updated + unchanged + missing + failed;
}

class PantryModel extends ChangeNotifier {
  PantryModel(
    this._store, {
    OffClient? off,
    DateTime Function()? clock,
    Future<void> Function(Duration)? wait,
  })  : _off = off ?? OffClient(),
        _clock = clock ?? DateTime.now,
        _wait = wait ?? ((d) => Future<void>.delayed(d));

  /// Pause between lookups in a bulk refresh. Open Food Facts asks for
  /// restraint on their free API; 46 products back to back without it reads
  /// as a scraper. Injectable so tests don't sleep.
  static const refreshPause = Duration(milliseconds: 700);

  final ProductStore? _store;
  final OffClient _off;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _wait;

  List<Product> _products = const [];
  int _skipped = 0;
  bool _loaded = false;
  bool _loading = false;
  bool _loadFailed = false;
  Future<void>? _scanInFlight;
  bool _busy = false;
  bool _refreshing = false;
  int _refreshDone = 0;
  int _refreshTotal = 0;

  List<Product> get products => List.unmodifiable(_products);
  bool get loaded => _loaded;

  /// The folder scan is running — the tab shows a spinner instead of an
  /// honest-looking "0 products". Deliberately not [busy]: a load must
  /// never hold the Scan button.
  bool get loading => _loading;

  /// The first scan threw before anything loaded — the tab offers a retry
  /// instead of spinning forever on a transient read failure.
  bool get loadFailed => _loadFailed;

  /// A lookup is in flight — the tab shows progress and holds the scan CTA.
  bool get busy => _busy;

  /// A bulk re-fetch is running; [refreshDone]/[refreshTotal] drive the
  /// progress line so a 46-product sweep never looks like a hang.
  bool get refreshing => _refreshing;
  int get refreshDone => _refreshDone;
  int get refreshTotal => _refreshTotal;

  /// Barcoded products are the only ones OFF can be asked about again — and
  /// hand-edited files are off the table too: the bulk sweep must never undo
  /// a correction the user typed in (Arnar, 2026-08-19).
  int get refreshableCount =>
      _products.where((p) => p.barcode.isNotEmpty && !p.userEdited).length;

  /// Hand-edited products on the shelf — the confirm dialog names how many
  /// files the bulk refresh will leave alone.
  int get editedCount => _products.where((p) => p.userEdited).length;

  /// Foreign/unparseable files in the pantry folder — surfaced, never fatal.
  int get skipped => _skipped;

  /// Header caption, grocery's honest-count idiom ("0 products" = empty state).
  String get caption {
    final n = _products.length;
    return '$n product${n == 1 ? '' : 's'}';
  }

  /// Idempotent in flight, not just after: every caller asking during the
  /// first scan awaits the SAME scan — the store is read once, however many
  /// screens boot at once.
  Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    return _scanInFlight ??= rescan().whenComplete(() => _scanInFlight = null);
  }

  Future<void> rescan() async {
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final res = await _store?.listAll() ?? const PantryResult([], 0);
      _products = res.products;
      _skipped = res.skipped;
      _loaded = true;
    } on Exception {
      // Kept as state, never thrown: the scan also runs as a fire-and-forget
      // boot warm, where a throw would be an unhandled async error on every
      // start. The tab draws a retry instead of an eternal spinner; a truly
      // lost grant is the boot gate's job on next start.
      _loadFailed = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Scanned digits → OFF lookup → save. Never throws; every outcome is a
  /// typed [PantryAddOutcome] the tab can show honestly.
  Future<PantryAddOutcome> addByBarcode(String barcode) async {
    _busy = true;
    notifyListeners();
    try {
      final wasKnown = _products.any((p) => p.id == barcode);
      final result = await _off.lookup(barcode);
      switch (result) {
        case OffFound(:final product):
          return PantryAdded(await _save(_fromOff(product)),
              wasKnown: wasKnown);
        case OffNotFound():
          return PantryNotFound(barcode);
        case OffUnavailable(:final message):
          return PantryUnavailable(message);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Ask Open Food Facts about every barcoded product on the shelf again and
  /// rewrite the files whose data changed. This is the only route to the
  /// vitamins and minerals for products saved by a build that kept just the
  /// seven macros — rescanning 46 packs by hand is not a plan.
  ///
  /// The user's own photo, the date they added it and the barcode all survive
  /// ([Product.copyWith] carries them); only OFF's own fields are replaced.
  /// A product OFF can't answer for is left exactly as it was, and a product
  /// the user edited by hand is never asked about at all — [refreshOne] is
  /// the deliberate door for those.
  Future<PantryRefreshReport> refreshAll() async {
    final targets = [
      for (final p in _products)
        if (p.barcode.isNotEmpty && !p.userEdited) p
    ];
    _refreshing = true;
    _refreshDone = 0;
    _refreshTotal = targets.length;
    notifyListeners();

    var updated = 0, unchanged = 0, missing = 0, failed = 0;
    try {
      for (var i = 0; i < targets.length; i++) {
        if (i > 0) await _wait(refreshPause);
        final current = byId(targets[i].id) ?? targets[i];
        final result = await _off.lookup(current.barcode);
        switch (result) {
          case OffFound(:final product):
            final merged = _merge(current, product);
            if (_sameAs(current, merged)) {
              unchanged++;
            } else {
              await _persist(merged);
              updated++;
            }
          case OffNotFound():
            missing++;
          case OffUnavailable():
            failed++;
        }
        _refreshDone = i + 1;
        notifyListeners();
      }
    } finally {
      _refreshing = false;
      notifyListeners();
    }
    return PantryRefreshReport(
        updated: updated,
        unchanged: unchanged,
        missing: missing,
        failed: failed);
  }

  /// OFF's fields onto an existing file. Absent OFF fields keep what the file
  /// already had rather than blanking it — a name that vanished from OFF is
  /// not a reason to lose the product's name here.
  Product _merge(Product current, OffProduct off) {
    final name = off.name?.trim();
    final autoTag = _categoryOf(off);
    return current.copyWith(
      name: (name == null || name.isEmpty) ? null : name,
      brand: off.brands,
      quantity: off.quantity,
      nutriments: Nutriments.fromMap(Map.of(off.nutriments.values)),
      // Servings the user typed in are theirs — a refresh only FILLS an
      // empty list, it never overwrites a portion they measured themselves.
      servings: current.servings.isEmpty ? _offServings(off) : null,
      defaultServing: current.servings.isEmpty && _offServings(off).isNotEmpty
          ? 0
          : null,
      // Same fill-only stance for the shelf category: tags the user chose
      // stay theirs; only a bare product gets the auto one.
      tags: current.tags.isEmpty && autoTag != null ? [autoTag] : null,
    );
  }

  /// Nothing worth a disk write. Compared on the fields a refresh can touch.
  bool _sameAs(Product a, Product b) =>
      a.name == b.name &&
      a.brand == b.brand &&
      a.quantity == b.quantity &&
      mapEquals(a.nutriments?.values, b.nutriments?.values) &&
      _sameServings(a.servings, b.servings) &&
      listEquals(a.tags, b.tags);

  static bool _sameServings(List<Serving> a, List<Serving> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].label != b[i].label || a[i].grams != b[i].grams) return false;
    }
    return true;
  }

  /// Ask OFF about ONE product again, deliberately — the only path that may
  /// overwrite a hand-edited file, and doing so hands the file back to OFF:
  /// the userEdited flag clears (Arnar, 2026-08-19). Outcomes mirror
  /// [addByBarcode] so the detail screen shows the same honest three-way.
  Future<PantryAddOutcome> refreshOne(String id) async {
    _busy = true;
    notifyListeners();
    try {
      final current = byId(id);
      if (current == null || current.barcode.isEmpty) {
        return PantryUnavailable(
            'This product has no barcode — nothing to look up.');
      }
      final result = await _off.lookup(current.barcode);
      switch (result) {
        case OffFound(:final product):
          final saved =
              await _persist(_merge(current, product).copyWith(userEdited: false));
          return PantryAdded(saved, wasKnown: true);
        case OffNotFound():
          return PantryNotFound(current.barcode);
        case OffUnavailable(:final message):
          return PantryUnavailable(message);
      }
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Write one product in place, keeping list order — a refresh must not
  /// reshuffle the shelf under the user's thumb the way a fresh scan does.
  Future<Product> _persist(Product product) async {
    final saved = await _store?.save(product) ?? product;
    _replace(saved);
    return saved;
  }

  Future<void> remove(String id) async {
    await _store?.delete(id);
    _products = [
      for (final p in _products)
        if (p.id != id) p
    ];
    notifyListeners();
  }

  /// User's own photo on a product — no store (test seam) keeps the ref
  /// in memory only, same degrade as every other op.
  Future<void> attachImage(Product product, File photo) async {
    final updated = await _store?.attachImage(product, photo) ??
        product.copyWith(image: 'images/${product.id}.jpg');
    _replace(updated);
  }

  Future<void> removeImage(Product product) async {
    final updated = await _store?.removeImage(product) ??
        product.copyWith(clearImage: true);
    _replace(updated);
  }

  /// Resolved photo file for display; null = unset, store-less, or foreign.
  File? imageFileOf(Product product) => _store?.imageFile(product);

  /// Row/detail lookups after a mutation: same id, fresh fields.
  Product? byId(String id) {
    for (final p in _products) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _replace(Product updated) {
    _products = [
      for (final p in _products) p.id == updated.id ? updated : p
    ];
    notifyListeners();
  }

  Product _fromOff(OffProduct off) {
    final name = off.name?.trim();
    final n = off.nutriments;
    return Product(
      schemaVersion: Product.currentSchemaVersion,
      barcode: off.barcode,
      // OFF entries can carry macros but no name; the file still needs one
      // (validator: empty name blocks the save).
      name: (name == null || name.isEmpty) ? 'Product ${off.barcode}' : name,
      brand: off.brands,
      quantity: off.quantity,
      source: 'off',
      addedAt: _clock().toUtc().toIso8601String(),
      // Everything OFF sent, vitamins and minerals included — the keys
      // already match the product file's.
      nutriments: Nutriments.fromMap(Map.of(n.values)),
      servings: _offServings(off),
      // The pack's own portion is what a label reader expects preselected;
      // 100 g is always still one tap away (Product.servingOptions).
      defaultServing: _offServings(off).isEmpty ? null : 0,
      // Shelf category from OFF's classification — the first milk scanned
      // arrives already wearing "Dairy". No match → no tag, never a guess.
      tags: switch (_categoryOf(off)) {
        final c? => [c],
        null => const [],
      },
    );
  }

  static String? _categoryOf(OffProduct off) => categoryForOff(
        categoriesTags: off.categoriesTags,
        foodGroupsTags: off.foodGroupsTags,
      );

  /// OFF's serving fields as a loggable portion. Only a portion with real
  /// grams survives: `serving_size` alone ("1 cup") cannot be costed against
  /// per-100 g nutriments, and a portion with no weight is a lie in a diary.
  static List<Serving> _offServings(OffProduct off) {
    final grams = off.servingGrams;
    if (grams == null || grams <= 0) return const [];
    final printed = off.servingSize?.trim();
    return [
      Serving(
        label: (printed == null || printed.isEmpty) ? '1 serving' : printed,
        grams: grams,
      )
    ];
  }

  /// Tags only, userEdited untouched: picking a shelf category is shelving,
  /// not a data correction — it must not shield the file from bulk refresh
  /// (whose _merge already never overwrites a non-empty tag list).
  Future<void> setTags(String id, List<String> tags) async {
    final current = byId(id);
    if (current == null) return;
    await _persist(current.copyWith(tags: tags));
  }

  /// Import a starter package: every food lands as its own normal product
  /// file. A food whose id is already on the shelf is SKIPPED, never
  /// overwritten — the user's version of "Carrot" outranks the bundled one.
  Future<({int added, int skipped})> addStarterFoods(
      List<StarterFood> foods) async {
    var added = 0, skipped = 0;
    final stamp = _clock().toUtc().toIso8601String();
    for (final food in foods) {
      final product = food.toProduct(addedAt: stamp);
      if (byId(product.id) != null) {
        skipped++;
        continue;
      }
      await _save(product);
      added++;
    }
    return (added: added, skipped: skipped);
  }

  /// Create or overwrite a product the user typed in themselves — the
  /// no-barcode door (manual_product_screen.dart) and the edit door for a
  /// scanned product Open Food Facts got wrong. Upsert by file stem, like a
  /// re-scan: one product, one file, never a duplicate. Every hand-save marks
  /// the file as the user's — [refreshAll] keeps its hands off it after this.
  Future<Product> upsert(Product product) =>
      _save(product.copyWith(userEdited: true));

  Future<Product> _save(Product product) async {
    final saved = await _store?.save(product) ?? product;
    _products = [
      saved,
      for (final p in _products)
        if (p.id != saved.id) p
    ];
    notifyListeners();
    return saved;
  }
}
