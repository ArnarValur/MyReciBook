// The durable half of the fair-use ledger (audit B2, design in
// docs/ai-cap-mechanics.md §1).
//
// Why this file exists: the in-memory ledger is only correct inside one
// process. Cloud Run scales to zero and scales out, so counts evaporated on
// cold start and split across instances — which made the cap in the listing a
// promise the code could not keep.
//
// One document per bucket at quota/{key}, one control document at
// control/global for the daily circuit breaker, and one Firestore transaction
// per rescue that reads both, walks the spending ladder and commits the
// charge. Cost is one read + one write per rescue — inside the free tier at
// every scale this project can reach.
//
// Nothing here stores recipe content. The document holds counters, timestamps
// and a status, exactly as constraint 3 requires.

import 'dart:async';
import 'dart:math';

import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import 'usage_counter.dart';

/// Firestore-backed [UsageLedger]. Construct with [connect] on Cloud Run,
/// where Application Default Credentials come from the metadata server.
class FirestoreUsageLedger implements UsageLedger {
  FirestoreUsageLedger({
    required fs.FirestoreApi api,
    required String projectId,
    this.cap = kDefaultYearlyCap,
    this.perMinuteLimit = 10,
    this.globalDailyLimit = 2000,
    this.graceDays = kGraceDays,
    this.perDayLimit = kPerDayLimit,
    this.maxRetries = 4,
    DateTime Function()? now,
  })  : _api = api,
        _database = 'projects/$projectId/databases/(default)',
        _now = now ?? DateTime.now;

  final fs.FirestoreApi _api;
  final String _database;
  final DateTime Function() _now;
  final int cap;
  final int perMinuteLimit;
  final int globalDailyLimit;

  /// See [kGraceDays] — the free fortnight. Pre-billing it runs from first
  /// contact; with billing it must be seeded from Google's purchaseTime.
  final int graceDays;

  /// See [kPerDayLimit] — the spend-rate governor, so a whole allowance
  /// cannot be drained in an afternoon.
  final int perDayLimit;

  /// Firestore aborts a transaction on write contention; that is expected
  /// under a burst, not an error. Retries use jittered backoff.
  final int maxRetries;

  String get _documents => '$_database/documents';

  /// Application Default Credentials — the Cloud Run service account. No key
  /// file anywhere; the runbook grants the account `roles/datastore.user`.
  static Future<FirestoreUsageLedger> connect({
    required String projectId,
    int cap = kDefaultYearlyCap,
    int perMinuteLimit = 10,
    int globalDailyLimit = 2000,
    int graceDays = kGraceDays,
    int perDayLimit = kPerDayLimit,
  }) async {
    final client = await auth.clientViaApplicationDefaultCredentials(
        scopes: [fs.FirestoreApi.datastoreScope]);
    return FirestoreUsageLedger(
      api: fs.FirestoreApi(client),
      projectId: projectId,
      cap: cap,
      perMinuteLimit: perMinuteLimit,
      globalDailyLimit: globalDailyLimit,
      graceDays: graceDays,
      perDayLimit: perDayLimit,
    );
  }

  @override
  Future<bool> globalBreakerTripped() async {
    try {
      final doc = await _get('control/global');
      if (doc == null) return false;
      final day = _int(doc, 'day');
      final count = _int(doc, 'count');
      return day == _todayNumber() && count >= globalDailyLimit;
    } catch (_) {
      // Fail OPEN on a read error: the breaker is a cost guard, not a
      // correctness one, and a Firestore blip must not look like an outage.
      return false;
    }
  }

  @override
  Future<ReservationOutcome> reserve(String bucketKey) async {
    var attempt = 0;
    while (true) {
      try {
        return await _reserveOnce(bucketKey);
      } on fs.DetailedApiRequestError catch (e) {
        // 409 ABORTED = another request touched the same document first.
        final retryable = e.status == 409 || e.status == 503;
        if (!retryable || attempt >= maxRetries) rethrow;
        attempt++;
        await Future<void>.delayed(
            Duration(milliseconds: 40 * attempt + Random().nextInt(60)));
      }
    }
  }

  Future<ReservationOutcome> _reserveOnce(String bucketKey) async {
    final now = _now().toUtc();
    final txn = await _api.projects.databases.documents
        .beginTransaction(fs.BeginTransactionRequest(), _database);
    final txnId = txn.transaction;
    if (txnId == null) {
      throw StateError('Firestore returned no transaction id');
    }
    var committed = false;
    try {
      final quotaPath = 'quota/${_safeKey(bucketKey)}';
      final quota = await _get(quotaPath, transaction: txnId);
      final control = await _get('control/global', transaction: txnId);

      // ---- global circuit breaker (§3 layer 3) -------------------------
      final today = _todayNumber();
      final controlDay = control == null ? today : _int(control, 'day');
      var globalCount = controlDay == today ? _int(control, 'count') : 0;
      if (globalCount >= globalDailyLimit) {
        return const ReservationOutcome(
            allowed: false, denyReason: 'globally_busy');
      }

      // ---- the bucket --------------------------------------------------
      final isNew = quota == null;
      final status = isNew ? 'active' : _str(quota, 'status') ?? 'active';
      final bucketCap = isNew ? cap : (_int(quota, 'cap', fallback: cap));
      var used = isNew ? 0 : _int(quota, 'used');
      var graceUsed = isNew ? 0 : _int(quota, 'graceUsed');
      var topup = isNew ? 0 : _int(quota, 'topupBalance');
      var resetsAt = isNew
          ? DateTime.utc(now.year + 1, now.month, now.day)
          : (_time(quota, 'resetsAt') ??
              DateTime.utc(now.year + 1, now.month, now.day));
      final graceUntil = isNew
          ? now.add(Duration(days: graceDays))
          : (_time(quota, 'graceUntil') ?? now);

      if (status != 'active') {
        return ReservationOutcome(
            allowed: false, denyReason: 'voided', cap: bucketCap);
      }

      // ---- per-bucket rate limit (§3 layer 2) --------------------------
      // A count plus the window's start, rather than a list of timestamps:
      // one integer and one timestamp survive a document round-trip cheaply.
      var windowStart = isNew ? now : (_time(quota, 'windowStart') ?? now);
      var windowCount = isNew ? 0 : _int(quota, 'windowCount');
      if (now.difference(windowStart).inSeconds >= 60) {
        windowStart = now;
        windowCount = 0;
      }
      if (windowCount >= perMinuteLimit) {
        return ReservationOutcome(
          allowed: false,
          denyReason: 'rate_limited',
          used: used,
          cap: bucketCap,
          topupBalance: topup,
          graceUsed: graceUsed,
          resetsAt: resetsAt,
          graceUntil: graceUntil,
        );
      }

      // ---- per-bucket daily ceiling ------------------------------------
      // Before the ladder, so it governs grace and included allowance alike.
      var bucketDay = isNew ? today : _int(quota, 'day', fallback: today);
      var dayCount = isNew ? 0 : _int(quota, 'dayCount');
      if (bucketDay != today) {
        bucketDay = today;
        dayCount = 0;
      }
      if (dayCount >= perDayLimit) {
        return ReservationOutcome(
          allowed: false,
          denyReason: 'daily_limit',
          used: used,
          cap: bucketCap,
          topupBalance: topup,
          graceUsed: graceUsed,
          resetsAt: resetsAt,
          graceUntil: graceUntil,
        );
      }

      // ---- lazy anniversary reset (§1: no cron) ------------------------
      if (now.isAfter(resetsAt)) {
        used = 0;
        while (!resetsAt.isAfter(now)) {
          resetsAt =
              DateTime.utc(resetsAt.year + 1, resetsAt.month, resetsAt.day);
        }
      }

      // ---- the spending ladder -----------------------------------------
      QuotaBucket? charged;
      if (now.isBefore(graceUntil) && graceUsed < kGraceCeiling) {
        charged = QuotaBucket.grace;
        graceUsed++;
      } else if (used < bucketCap) {
        charged = QuotaBucket.included;
        used++;
      } else if (topup > 0) {
        charged = QuotaBucket.topup;
        topup--;
      }
      if (charged == null) {
        return ReservationOutcome(
          allowed: false,
          denyReason: 'cap_exceeded',
          used: used,
          cap: bucketCap,
          topupBalance: topup,
          graceUsed: graceUsed,
          resetsAt: resetsAt,
          graceUntil: graceUntil,
        );
      }
      windowCount++;
      dayCount++;
      globalCount++;

      await _api.projects.databases.documents.commit(
        fs.CommitRequest(
          transaction: txnId,
          writes: [
            _write(quotaPath, {
              'status': _s(status),
              'cap': _i(bucketCap),
              'used': _i(used),
              'graceUsed': _i(graceUsed),
              'topupBalance': _i(topup),
              'resetsAt': _t(resetsAt),
              'graceUntil': _t(graceUntil),
              'windowStart': _t(windowStart),
              'windowCount': _i(windowCount),
              'day': _i(bucketDay),
              'dayCount': _i(dayCount),
              'test': fs.Value(booleanValue: false),
            }),
            _write('control/global', {
              'day': _i(today),
              'count': _i(globalCount),
            }),
          ],
        ),
        _database,
      );
      committed = true;

      return ReservationOutcome(
        allowed: true,
        bucket: charged,
        used: used,
        cap: bucketCap,
        topupBalance: topup,
        graceUsed: graceUsed,
        resetsAt: resetsAt,
        graceUntil: graceUntil,
      );
    } finally {
      if (!committed) {
        // Every early return above leaves the transaction open; rolling back
        // frees the locks immediately instead of waiting for expiry.
        try {
          await _api.projects.databases.documents
              .rollback(fs.RollbackRequest(transaction: txnId), _database);
        } catch (_) {}
      }
    }
  }

  @override
  Future<void> refund(String bucketKey, QuotaBucket bucket) async {
    // Best-effort and deliberately NOT transactional: a refund that fails
    // costs the user one rescue, while a refund that throws would replace the
    // real upstream error with a confusing one.
    try {
      final path = 'quota/${_safeKey(bucketKey)}';
      final doc = await _get(path);
      if (doc == null) return;
      final fields = <String, fs.Value>{
        // Give the day's slot back too, or a run of upstream failures would
        // eat the user's daily headroom for nothing.
        'dayCount': _i(max(0, _int(doc, 'dayCount') - 1)),
      };
      switch (bucket) {
        case QuotaBucket.grace:
          fields['graceUsed'] = _i(max(0, _int(doc, 'graceUsed') - 1));
        case QuotaBucket.included:
          fields['used'] = _i(max(0, _int(doc, 'used') - 1));
        case QuotaBucket.topup:
          fields['topupBalance'] = _i(_int(doc, 'topupBalance') + 1);
      }
      await _api.projects.databases.documents
          .commit(fs.CommitRequest(writes: [_write(path, fields)]), _database);
    } catch (_) {}
  }

  // ---- Firestore plumbing ------------------------------------------------

  Future<fs.Document?> _get(String relPath, {String? transaction}) async {
    try {
      return await _api.projects.databases.documents
          .get('$_documents/$relPath', transaction: transaction);
    } on fs.DetailedApiRequestError catch (e) {
      if (e.status == 404) return null; // absent is a normal first contact
      rethrow;
    }
  }

  /// A merge write: updateMask lists exactly the fields we set, so a field
  /// this proxy does not know about (a future top-up column, say) survives.
  fs.Write _write(String relPath, Map<String, fs.Value> fields) => fs.Write(
        update: fs.Document(name: '$_documents/$relPath', fields: fields),
        updateMask: fs.DocumentMask(fieldPaths: fields.keys.toList()),
      );

  int _todayNumber() => _now().toUtc().millisecondsSinceEpoch ~/ 86400000;

  /// Firestore document ids may not contain '/'. Install ids and sha256 hex
  /// never do, but the id arrives from the network — normalize rather than
  /// trust. The proxy's own shape check has already run by this point.
  static String _safeKey(String key) => key.replaceAll('/', '_');
}

// ---- Value helpers -------------------------------------------------------

fs.Value _i(int v) => fs.Value(integerValue: '$v');
fs.Value _s(String v) => fs.Value(stringValue: v);
fs.Value _t(DateTime v) =>
    fs.Value(timestampValue: v.toUtc().toIso8601String());

int _int(fs.Document? doc, String field, {int fallback = 0}) {
  final raw = doc?.fields?[field]?.integerValue;
  return raw == null ? fallback : (int.tryParse(raw) ?? fallback);
}

String? _str(fs.Document? doc, String field) =>
    doc?.fields?[field]?.stringValue;

DateTime? _time(fs.Document? doc, String field) {
  final raw = doc?.fields?[field]?.timestampValue;
  return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
}

/// Closes the ledger's underlying HTTP client. Only used by tests and local
/// runs; Cloud Run tears the process down instead.
void closeAuthClient(http.Client client) => client.close();
