/// The per-buyer fair-use ledger — the ONE piece of state the proxy is allowed
/// (context.md constraint 3, amended 2026-08-06: stateless EXCEPT this; the
/// proxy never stores recipe content, so nothing here may hold request bodies).
///
/// Shape and spending order come from docs/ai-cap-mechanics.md §1, agreed —
/// this file implements that design, it does not reopen it.
///
/// The slot is RESERVED before Gemini is called and REFUNDED if the call
/// fails, so a queue running in parallel cannot overshoot a nearly-empty cap
/// and a failed extraction never spends the user's allowance.
library;

/// Working cap: 1200 rescues a year ("100 a month"), moved from 600 on
/// 2026-08-21. Nothing prints in the listing until closed-test usage confirms
/// it; once printed it can rise, never fall.
const int kDefaultYearlyCap = 1200;

/// Grace spending before the counter starts biting — a quiet ceiling, never a
/// hard stop (§1). Applies inside [ReservationOutcome.graceUntil].
const int kGraceCeiling = 300;

/// Length of the grace window, in days. **Fourteen — this is the offer**
/// (Arnar, confirmed 2026-08-21): first two weeks free, then 1200 over the
/// year. Not an implementation detail to be tuned away.
///
/// Grace spending is still fully RECORDED — it lands in `graceUsed`, its own
/// counter, so total usage is always `graceUsed + used`. Free does not mean
/// unmeasured, and the closed test's fair-use data survives intact.
///
/// Pre-billing the window runs from first contact. When billing lands it must
/// be seeded from Google's `purchaseTimeMillis` instead (§1), so a reinstall
/// cannot restart the free fortnight.
const int kGraceDays = 14;

/// Per-bucket daily ceiling (§3 layer 2, extended 2026-08-21 on Arnar's
/// catch: "we also need to make sure that users don't do 1000 requests a day
/// for the first 14 days").
///
/// The minute limit stops scripted hammering; the yearly cap stops the total.
/// Neither stops a user — or a lifted APK — draining a whole allowance in an
/// afternoon. At 1200/year the honest average is ~3/day, and even emptying a
/// camera roll is tens, not hundreds. Fifty is generous for a real cook and
/// ruinous for a scraper: it puts a floor of 6 days on the 300 grace rescues
/// and 24 days on a full year's 1200.
///
/// Deliberately NOT a hard stop on the year: it is a spend-rate governor, so
/// the answer is "not today", never "never".
const int kPerDayLimit = 50;

/// Which bucket paid for a rescue. Order is deliberate: the expiring included
/// allowance burns before never-expiring paid top-ups, so a user never loses
/// paid credit while free allowance sat unused.
enum QuotaBucket { grace, included, topup }

/// What a reserve attempt did, and everything the app's counter UI needs.
/// Returned verbatim to the client in the `quota` field of every response.
class ReservationOutcome {
  const ReservationOutcome({
    required this.allowed,
    this.bucket,
    this.denyReason,
    this.used = 0,
    this.cap = kDefaultYearlyCap,
    this.topupBalance = 0,
    this.graceUsed = 0,
    this.resetsAt,
    this.graceUntil,
  });

  final bool allowed;

  /// Which bucket was charged — what [UsageLedger.refund] gives back.
  final QuotaBucket? bucket;

  /// 'cap_exceeded' or 'voided'. Null when [allowed].
  final String? denyReason;

  final int used;
  final int cap;
  final int topupBalance;
  final int graceUsed;
  final DateTime? resetsAt;
  final DateTime? graceUntil;

  /// The `quota` object every response carries, so the app's counter is
  /// current with zero extra calls (§1, §2).
  Map<String, Object?> toJson() => {
        'used': used,
        'cap': cap,
        // Free-window spending, reported separately so the app can say "still
        // in your first two weeks" rather than showing a cap that is not
        // biting yet — and so total usage is never lost.
        'grace_used': graceUsed,
        'topup_balance': topupBalance,
        if (resetsAt != null) 'resets_at': resetsAt!.toUtc().toIso8601String(),
        if (graceUntil != null)
          'grace_until': graceUntil!.toUtc().toIso8601String(),
      };
}

/// One rescue's worth of quota, reserved and possibly given back.
abstract class UsageLedger {
  /// Walks the ladder — grace → included allowance → top-up → gentle stop —
  /// and charges exactly one slot, atomically. [bucketKey] is the install id
  /// before billing exists and sha256(purchaseToken) after; the ledger does
  /// not care which, it only ever sees an opaque key.
  Future<ReservationOutcome> reserve(String bucketKey);

  /// Hands a reserved slot back after a failed extraction. Never throws — a
  /// lost refund costs the user one rescue, a thrown refund costs them the
  /// error message telling them to retry.
  Future<void> refund(String bucketKey, QuotaBucket bucket);

  /// True when the global daily circuit breaker has tripped (§3 layer 3).
  /// Checked inside [reserve]; exposed for the health endpoint.
  Future<bool> globalBreakerTripped();
}

/// In-memory ledger — correct only in a single process, so it is the TEST
/// implementation and the local-dev one. Production runs the Firestore ledger;
/// Cloud Run scales to zero and out, which would make these counts evaporate
/// and split (audit B2).
class InMemoryUsageLedger implements UsageLedger {
  InMemoryUsageLedger({
    DateTime Function()? now,
    this.cap = kDefaultYearlyCap,
    this.perMinuteLimit = 10,
    this.globalDailyLimit = 2000,
    this.graceDays = kGraceDays,
    this.perDayLimit = kPerDayLimit,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final int cap;
  final int perMinuteLimit;
  final int globalDailyLimit;
  final int graceDays;
  final int perDayLimit;

  final Map<String, _Bucket> _buckets = {};
  int _globalDay = -1;
  int _globalCount = 0;

  @override
  Future<bool> globalBreakerTripped() async {
    _rollGlobalDay();
    return _globalCount >= globalDailyLimit;
  }

  void _rollGlobalDay() {
    final day = _now().toUtc().millisecondsSinceEpoch ~/ 86400000;
    if (day != _globalDay) {
      _globalDay = day;
      _globalCount = 0;
    }
  }

  @override
  Future<ReservationOutcome> reserve(String bucketKey) async {
    final now = _now().toUtc();
    _rollGlobalDay();
    if (_globalCount >= globalDailyLimit) {
      return const ReservationOutcome(
          allowed: false, denyReason: 'globally_busy');
    }
    final b =
        _buckets.putIfAbsent(bucketKey, () => _Bucket(now, cap, graceDays));
    if (b.status != 'active') {
      return ReservationOutcome(
          allowed: false, denyReason: 'voided', cap: b.cap);
    }
    // Sliding one-minute window (§3 layer 2).
    b.recent.removeWhere((t) => now.difference(t).inSeconds >= 60);
    if (b.recent.length >= perMinuteLimit) {
      return ReservationOutcome(
        allowed: false,
        denyReason: 'rate_limited',
        used: b.used,
        cap: b.cap,
        topupBalance: b.topupBalance,
        graceUsed: b.graceUsed,
        resetsAt: b.resetsAt,
        graceUntil: b.graceUntil,
      );
    }
    // Per-bucket daily ceiling. Checked before the ladder so it applies to
    // grace and included allowance alike — the free fortnight is exactly when
    // a drainer would strike.
    final today = now.millisecondsSinceEpoch ~/ 86400000;
    if (b.day != today) {
      b.day = today;
      b.dayCount = 0;
    }
    if (b.dayCount >= perDayLimit) {
      return ReservationOutcome(
        allowed: false,
        denyReason: 'daily_limit',
        used: b.used,
        cap: b.cap,
        topupBalance: b.topupBalance,
        graceUsed: b.graceUsed,
        resetsAt: b.resetsAt,
        graceUntil: b.graceUntil,
      );
    }
    // Lazy anniversary reset — no cron (§1).
    if (now.isAfter(b.resetsAt)) {
      b.used = 0;
      b.resetsAt = _nextAnniversary(b.resetsAt, now);
    }
    final bucket = _pick(b, now);
    if (bucket == null) {
      return ReservationOutcome(
        allowed: false,
        denyReason: 'cap_exceeded',
        used: b.used,
        cap: b.cap,
        topupBalance: b.topupBalance,
        graceUsed: b.graceUsed,
        resetsAt: b.resetsAt,
        graceUntil: b.graceUntil,
      );
    }
    switch (bucket) {
      case QuotaBucket.grace:
        b.graceUsed++;
      case QuotaBucket.included:
        b.used++;
      case QuotaBucket.topup:
        b.topupBalance--;
    }
    b.recent.add(now);
    b.dayCount++;
    _globalCount++;
    return ReservationOutcome(
      allowed: true,
      bucket: bucket,
      used: b.used,
      cap: b.cap,
      topupBalance: b.topupBalance,
      graceUsed: b.graceUsed,
      resetsAt: b.resetsAt,
      graceUntil: b.graceUntil,
    );
  }

  @override
  Future<void> refund(String bucketKey, QuotaBucket bucket) async {
    final b = _buckets[bucketKey];
    if (b == null) return;
    switch (bucket) {
      case QuotaBucket.grace:
        if (b.graceUsed > 0) b.graceUsed--;
      case QuotaBucket.included:
        if (b.used > 0) b.used--;
      case QuotaBucket.topup:
        b.topupBalance++;
    }
    if (b.dayCount > 0) b.dayCount--;
    if (_globalCount > 0) _globalCount--;
  }
}

/// Spending ladder, shared by both ledger implementations (§1).
QuotaBucket? _pick(_Bucket b, DateTime now) {
  if (now.isBefore(b.graceUntil) && b.graceUsed < kGraceCeiling) {
    return QuotaBucket.grace;
  }
  if (b.used < b.cap) return QuotaBucket.included;
  if (b.topupBalance > 0) return QuotaBucket.topup;
  return null;
}

/// Advances a passed anniversary to the next one after [now] — a bucket idle
/// for two years lands on the right date, not two resets behind.
DateTime _nextAnniversary(DateTime resetsAt, DateTime now) {
  var next = resetsAt;
  while (!next.isAfter(now)) {
    next = DateTime.utc(next.year + 1, next.month, next.day);
  }
  return next;
}

class _Bucket {
  _Bucket(DateTime firstSeen, this.cap, int graceDays)
      : resetsAt =
            DateTime.utc(firstSeen.year + 1, firstSeen.month, firstSeen.day),
        // graceDays 0 → graceUntil == firstSeen, and `now.isBefore(graceUntil)`
        // is false from the very first request: no grace, by construction.
        graceUntil = firstSeen.add(Duration(days: graceDays));

  String status = 'active';
  final int cap;
  int used = 0;
  int graceUsed = 0;
  int topupBalance = 0;
  DateTime resetsAt;
  final DateTime graceUntil;
  final List<DateTime> recent = [];
  int day = -1;
  int dayCount = 0;
}
