// Cloud Run entrypoint. All config via env:
//   GEMINI_API_KEY        required — refuses to boot without it. On Cloud Run
//                         this arrives from Secret Manager, never a literal.
//   GOOGLE_CLOUD_PROJECT  injected by Cloud Run; enables the Firestore ledger.
//                         Absent → in-memory ledger, which is correct ONLY in
//                         a single local process.
//   YEARLY_CAP            per-bucket fair-use cap, default 1200
//   PER_MINUTE_LIMIT      per-bucket rate limit, default 10
//   PER_DAY_LIMIT         per-bucket daily ceiling, default 50 — the
//                         spend-rate governor, so nobody drains the free
//                         fortnight or a whole year in an afternoon
//   GRACE_DAYS            free window, default 14 (the offer)
//   GLOBAL_DAILY_LIMIT    circuit breaker across all buckets, default 2000
//   APP_CHECK_ENFORCE     'true' to require a verified App Check token.
//                         THE one-line flip — see docs/runbook-dev-deploy.md.
//   FIREBASE_PROJECT_NUMBER  numeric project number, required to verify
//                         App Check tokens (the iss/aud claim carries it)
//   ALLOWED_MODELS        comma-separated, default gemini-3.5-flash-lite
//   PORT                  injected by Cloud Run, default 8080

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:myrecibook_proxy/app_check.dart';
import 'package:myrecibook_proxy/firestore_ledger.dart';
import 'package:myrecibook_proxy/proxy.dart';
import 'package:myrecibook_proxy/usage_counter.dart';

String? _env(String name) {
  final v = Platform.environment[name];
  return v == null || v.isEmpty ? null : v;
}

int _envInt(String name, int fallback) =>
    int.tryParse(_env(name) ?? '') ?? fallback;

Future<void> main() async {
  final key = _env('GEMINI_API_KEY');
  if (key == null) {
    stderr.writeln('GEMINI_API_KEY is not set — refusing to start.');
    exit(1);
  }
  final models = (_env('ALLOWED_MODELS') ?? 'gemini-3.5-flash-lite')
      .split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toSet();
  final cap = _envInt('YEARLY_CAP', kDefaultYearlyCap);
  final perMinute = _envInt('PER_MINUTE_LIMIT', 10);
  final perDay = _envInt('PER_DAY_LIMIT', kPerDayLimit);
  final graceDays = _envInt('GRACE_DAYS', kGraceDays);
  final globalDaily = _envInt('GLOBAL_DAILY_LIMIT', 2000);
  final port = _envInt('PORT', 8080);
  final appCheckEnforce = _env('APP_CHECK_ENFORCE')?.toLowerCase() == 'true';

  // ---- the ledger ------------------------------------------------------
  // Durable on Cloud Run, in-memory locally. Never silently in-memory in a
  // deployed environment: that was audit B2, and it made the advertised cap
  // unenforceable.
  final projectId = _env('GOOGLE_CLOUD_PROJECT');
  final UsageLedger ledger;
  if (projectId != null) {
    try {
      ledger = await FirestoreUsageLedger.connect(
        projectId: projectId,
        cap: cap,
        perMinuteLimit: perMinute,
        perDayLimit: perDay,
        graceDays: graceDays,
        globalDailyLimit: globalDaily,
      );
      stdout.writeln('ledger: Firestore (project $projectId)');
    } catch (e) {
      // Better a dead deploy than a live one that cannot count. An unmetered
      // proxy is an open Gemini bill.
      stderr.writeln('Firestore ledger unavailable — refusing to start: $e');
      exit(1);
    }
  } else {
    ledger = InMemoryUsageLedger(
      cap: cap,
      perMinuteLimit: perMinute,
      perDayLimit: perDay,
      graceDays: graceDays,
      globalDailyLimit: globalDaily,
    );
    stdout.writeln('ledger: IN-MEMORY (local dev only — counts do not persist)');
  }

  // ---- App Check -------------------------------------------------------
  AppCheckVerifier? appCheck;
  final projectNumber = _env('FIREBASE_PROJECT_NUMBER');
  if (projectNumber != null && projectId != null) {
    appCheck =
        AppCheckVerifier(projectNumber: projectNumber, projectId: projectId);
  }
  if (appCheckEnforce && appCheck == null) {
    stderr.writeln('APP_CHECK_ENFORCE=true but FIREBASE_PROJECT_NUMBER / '
        'GOOGLE_CLOUD_PROJECT are not both set — refusing to start.');
    exit(1);
  }

  final handler = const Pipeline()
      // Method + path + status only — request bodies are recipe content and
      // never touch a log (context.md constraint 3).
      .addMiddleware(logRequests())
      .addHandler(buildHandler(
        ProxyConfig(
          geminiApiKey: key,
          allowedModels: models,
          appCheckEnforced: appCheckEnforce,
        ),
        ledger: ledger,
        appCheck: appCheck,
      ));

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('extraction proxy listening on :${server.port}\n'
      '  models:        ${models.join(', ')}\n'
      '  cap:           $cap/bucket/year\n'
      '  free window:   $graceDays days (ceiling $kGraceCeiling)\n'
      '  rate limit:    $perMinute/min, $perDay/day per bucket\n'
      '  daily breaker: $globalDaily calls\n'
      '  app check:     ${appCheckEnforce ? 'ENFORCED' : 'off (not enforced)'}');
}
