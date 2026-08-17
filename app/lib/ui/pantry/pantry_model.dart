// Pantry view-model — GroceryModel's D3 stance applied to the food base:
// pure op → store persist → notify. A null store (test seam without pantry
// wiring) degrades to in-memory state — never crashes.
//
// The OFF lookup's three-way result surfaces verbatim as [PantryAddOutcome]:
// the UI must never read "OFF didn't answer" as "not in the database" — the
// shell-spike lesson from 2026-08-17, where throttling masqueraded as misses.

import 'package:flutter/foundation.dart';

import '../../data/off_client.dart';
import '../../data/product_store.dart';
import '../../domain/product.dart';

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

class PantryModel extends ChangeNotifier {
  PantryModel(this._store, {OffClient? off, DateTime Function()? clock})
      : _off = off ?? OffClient(),
        _clock = clock ?? DateTime.now;

  final ProductStore? _store;
  final OffClient _off;
  final DateTime Function() _clock;

  List<Product> _products = const [];
  int _skipped = 0;
  bool _loaded = false;
  bool _busy = false;

  List<Product> get products => List.unmodifiable(_products);
  bool get loaded => _loaded;

  /// A lookup is in flight — the tab shows progress and holds the scan CTA.
  bool get busy => _busy;

  /// Foreign/unparseable files in the pantry folder — surfaced, never fatal.
  int get skipped => _skipped;

  /// Header caption, grocery's honest-count idiom ("0 products" = empty state).
  String get caption {
    final n = _products.length;
    return '$n product${n == 1 ? '' : 's'}';
  }

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    await rescan();
  }

  Future<void> rescan() async {
    final res = await _store?.listAll() ?? const PantryResult([], 0);
    _products = res.products;
    _skipped = res.skipped;
    _loaded = true;
    notifyListeners();
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

  Future<void> remove(String id) async {
    await _store?.delete(id);
    _products = [
      for (final p in _products)
        if (p.id != id) p
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
      nutriments: Nutriments(
        kcal: n.energyKcal,
        fat: n.fat,
        saturatedFat: n.saturatedFat,
        carbs: n.carbohydrates,
        sugars: n.sugars,
        protein: n.proteins,
        salt: n.salt,
      ),
    );
  }

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
