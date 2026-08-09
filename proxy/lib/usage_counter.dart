/// Per-install fair-use counter — the ONE piece of state the proxy is allowed
/// (context.md constraint 3, amended 2026-08-06: stateless EXCEPT this; the
/// proxy never stores recipe content, so nothing here may hold request bodies).
///
/// In-memory is honest for the closed track: a single Cloud Run instance that
/// scales to zero simply forgets counts on cold start, which only ever errs in
/// the tester's favor. The interface is the seam for a durable store (decision
/// for Arnar — needs a cost call) before production scale-out.
abstract class UsageCounter {
  /// Increments and returns [installId]'s count for the current UTC calendar
  /// month.
  Future<int> increment(String installId);
}

class InMemoryUsageCounter implements UsageCounter {
  InMemoryUsageCounter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, int> _counts = {};
  String _month = '';

  @override
  Future<int> increment(String installId) async {
    final t = _now().toUtc();
    final month = '${t.year}-${t.month}';
    if (month != _month) {
      _month = month;
      _counts.clear();
    }
    return _counts[installId] = (_counts[installId] ?? 0) + 1;
  }
}
