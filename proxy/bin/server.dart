// Cloud Run entrypoint. All config via env:
//   GEMINI_API_KEY        required — refuses to boot without it. On Cloud Run
//                         this arrives from Secret Manager, never a literal.
//   GOOGLE_CLOUD_PROJECT  selects the Firestore ledger. Cloud Run does NOT set
//                         this itself (that is App Engine / Cloud Functions),
//                         so deploy.sh passes it and the metadata server is
//                         the fallback. Absent → in-memory ledger, which is
//                         correct ONLY in a single local process, and which
//                         this server REFUSES to use on Cloud Run.
//   INCLUDED_CAP          per-bucket included grant, default 1200 — never
//                         refills (Decision 1); YEARLY_CAP read as fallback
//   PER_MINUTE_LIMIT      per-bucket rate limit, default 10
//   PER_DAY_LIMIT         per-bucket daily ceiling, default 50 — the
//                         spend-rate governor, so nobody drains the free
//                         fortnight or the whole grant in an afternoon
//   GRACE_DAYS            free window, default 14 (the offer)
//   GLOBAL_DAILY_LIMIT    circuit breaker across all buckets, default 2000
//   APP_CHECK_ENFORCE     'true' to require a verified App Check token.
//                         THE one-line flip — see docs/runbook-dev-deploy.md.
//   FIREBASE_PROJECT_NUMBER  numeric project number, required to verify
//                         App Check tokens (the iss/aud claim carries it)
//   ALLOWED_MODELS        comma-separated, default gemini-3.5-flash-lite
//   PORT                  injected by Cloud Run, default 8080
//
// The website contact form (optional — absent, /contact simply 404s):
//   BREVO_API_KEY         from Secret Manager. Without it the route is off.
//   CONTACT_FROM_EMAIL    an AUTHENTICATED Brevo sender, default
//                         noreply@myrecibook.com
//   CONTACT_FROM_NAME     display name on the mail, default MyReciBook
//   CONTACT_TO_EMAIL      where messages land, default myrecibook@gmail.com
//   CONTACT_ALLOWED_ORIGINS  comma-separated exact origins allowed to POST.
//                         Empty means any origin, which is local dev only.

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:myrecibook_proxy/app_check.dart';
import 'package:myrecibook_proxy/contact.dart';
import 'package:myrecibook_proxy/firestore_ledger.dart';
import 'package:myrecibook_proxy/proxy.dart';
import 'package:myrecibook_proxy/usage_counter.dart';

String? _env(String name) {
  final v = Platform.environment[name];
  return v == null || v.isEmpty ? null : v;
}

int _envInt(String name, int fallback) =>
    int.tryParse(_env(name) ?? '') ?? fallback;

/// True when running on Cloud Run. K_SERVICE is part of the documented Cloud
/// Run container contract; GOOGLE_CLOUD_PROJECT is NOT — assuming otherwise is
/// what silently downgraded the first deploy to the in-memory ledger
/// (2026-08-21).
bool get _onCloudRun => _env('K_SERVICE') != null;

/// The project id, from the env var if deploy.sh passed one, else from the
/// metadata server, which is always right when it answers.
Future<String?> _resolveProjectId() async {
  final fromEnv = _env('GOOGLE_CLOUD_PROJECT') ?? _env('GCP_PROJECT');
  if (fromEnv != null) return fromEnv;
  if (!_onCloudRun) return null;
  try {
    final resp = await http.get(
      Uri.parse(
          'http://metadata.google.internal/computeMetadata/v1/project/project-id'),
      headers: {'Metadata-Flavor': 'Google'},
    ).timeout(const Duration(seconds: 3));
    if (resp.statusCode == 200 && resp.body.trim().isNotEmpty) {
      return resp.body.trim();
    }
  } catch (_) {}
  return null;
}

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
  // INCLUDED_CAP is the name; YEARLY_CAP still read so an old deploy config
  // cannot silently change the cap (the grant never refills — Decision 1).
  final cap = _envInt('INCLUDED_CAP', _envInt('YEARLY_CAP', kDefaultIncludedCap));
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
  final projectId = await _resolveProjectId();
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
  } else if (_onCloudRun) {
    // The guard that was missing. A deployed proxy that cannot count is an
    // open Gemini bill and an unenforceable cap (audit B2) — the exact thing
    // the Firestore ledger exists to prevent. Die loudly instead.
    stderr.writeln('Running on Cloud Run but no project id could be resolved '
        '— refusing to start with the in-memory ledger. Pass '
        'GOOGLE_CLOUD_PROJECT via --set-env-vars.');
    exit(1);
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

  // ---- the contact form ------------------------------------------------
  // Optional by design: a missing Brevo key turns the route off rather than
  // killing a deploy whose real job is extraction.
  ContactHandler? contact;
  final brevoKey = _env('BREVO_API_KEY');
  if (brevoKey != null) {
    contact = ContactHandler(ContactConfig(
      brevoApiKey: brevoKey,
      fromEmail: _env('CONTACT_FROM_EMAIL') ?? 'noreply@myrecibook.com',
      fromName: _env('CONTACT_FROM_NAME') ?? 'MyReciBook',
      toEmail: _env('CONTACT_TO_EMAIL') ?? 'myrecibook@gmail.com',
      allowedOrigins: (_env('CONTACT_ALLOWED_ORIGINS') ?? '')
          .split(',')
          .map((o) => o.trim())
          .where((o) => o.isNotEmpty)
          .toSet(),
    ));
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
        contact: contact,
      ));

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('extraction proxy listening on :${server.port}\n'
      '  models:        ${models.join(', ')}\n'
      '  cap:           $cap/bucket/year\n'
      '  free window:   $graceDays days (ceiling $kGraceCeiling)\n'
      '  rate limit:    $perMinute/min, $perDay/day per bucket\n'
      '  daily breaker: $globalDaily calls\n'
      '  app check:     ${appCheckEnforce ? 'ENFORCED' : 'off (not enforced)'}\n'
      '  contact form:  ${contact == null ? 'off (no BREVO_API_KEY)' : 'on'}');
}
