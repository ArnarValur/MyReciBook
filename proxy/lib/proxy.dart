// Thin extraction proxy (D2, senior review F3; hardened 2026-08-21 per the
// pre-launch audit B1–B3).
//
// A transparent relay for the ONE Gemini call the app makes
// (models/<model>:generateContent). The client keeps building the request it
// already speaks (spike-proven shape, assembled in
// app/lib/data/gemini_extractor.dart); this proxy's whole job is:
//   1. hold GEMINI_API_KEY server-side — it never ships in the APK and never
//      rides a URL (goes upstream as the x-goog-api-key header);
//   2. refuse anything that is not the extraction call (POST, allowlisted
//      model, bounded body) so a leaked proxy URL is not a general Gemini key;
//   3. prove the caller is the real app — Firebase App Check, backed by Play
//      Integrity (audit B1: a self-asserted install id proved nothing);
//   4. meter per-buyer usage against the fair-use cap through a DURABLE
//      ledger (audit B2: in-memory counts evaporated on every cold start);
//   5. hold the abuse line — per-bucket rate limit and a global daily circuit
//      breaker (§3 layers 2 and 3).
// Request bodies are forwarded, never stored, never logged.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

import 'app_check.dart';
import 'contact.dart';
import 'usage_counter.dart';

class ProxyConfig {
  const ProxyConfig({
    required this.geminiApiKey,
    this.allowedModels = const {'gemini-3.5-flash-lite'},
    this.maxBodyBytes = 25 * 1024 * 1024,
    this.upstreamBase = 'https://generativelanguage.googleapis.com',
    this.upstreamTimeout = const Duration(seconds: 150),
    this.appCheckEnforced = false,
  });

  final String geminiApiKey;
  final Set<String> allowedModels;

  /// Several screenshots per recipe, base64-inflated ~1.33x. 25 MB clears a
  /// worst-case batch; anything bigger is not a recipe.
  final int maxBodyBytes;

  final String upstreamBase;

  /// Slightly above the client's own 120 s timeout so the client, not the
  /// proxy, decides when to give up.
  final Duration upstreamTimeout;

  /// OFF until the app reaches the internal track and actually carries App
  /// Check tokens; the runbook's one-line flip turns it on. When true the
  /// proxy fails CLOSED — no token, no extraction.
  final bool appCheckEnforced;
}

/// Matches app-generated install ids (UUID-ish) and sha256 hex bucket keys;
/// rejects junk before it can become a ledger document id.
final _bucketKeyShape = RegExp(r'^[A-Za-z0-9-]{8,64}$');

final _pathShape = RegExp(r'^v1beta/models/([A-Za-z0-9.-]+):generateContent$');

Response _json(int status, Map<String, Object?> body) => Response(status,
    body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

Handler buildHandler(
  ProxyConfig config, {
  http.Client? client,
  UsageLedger? ledger,
  AppCheckVerifier? appCheck,
  ContactHandler? contact,
}) {
  final upstream = client ?? http.Client();
  final usage = ledger ?? InMemoryUsageLedger();

  return (Request request) async {
    // The website's contact form. Answered before every check below it: it
    // carries no install id, spends no rescue, and must never reach the
    // ledger or Gemini. Absent (no Brevo key configured) it simply 404s with
    // the rest of the unknown paths.
    final contactReply = contact?.maybeHandle(request);
    if (contactReply != null) return contactReply;

    // '/health', NOT '/healthz': Cloud Run's frontend reserves /healthz and
    // answers it with its own 404 HTML before the container ever sees it
    // (found the hard way on the first deploy, 2026-08-21). Both are accepted
    // here so a local caller using either still works.
    if (request.method == 'GET' &&
        (request.url.path == 'health' || request.url.path == 'healthz')) {
      // Deliberately says nothing about quota, keys or the ledger.
      return Response.ok('ok');
    }
    if (request.method != 'POST') {
      return _json(405, {'error': 'method_not_allowed'});
    }
    final match = _pathShape.firstMatch(request.url.path);
    if (match == null) {
      return _json(404, {'error': 'not_found'});
    }
    final model = match.group(1)!;
    if (!config.allowedModels.contains(model)) {
      return _json(403, {'error': 'model_not_allowed'});
    }

    // ---- who is calling (audit B1) --------------------------------------
    // The install id is the ledger KEY, never the proof of identity. App
    // Check is the proof. Before billing exists the key is the install id;
    // the schema and this line are what change when it becomes
    // sha256(purchaseToken) — nothing downstream cares.
    final bucketKey = request.headers['x-install-id'];
    if (bucketKey == null || !_bucketKeyShape.hasMatch(bucketKey)) {
      return _json(400, {'error': 'missing_install_id'});
    }
    if (config.appCheckEnforced) {
      final verifier = appCheck;
      if (verifier == null) {
        // Misconfiguration must not silently degrade into an open door.
        return _json(503, {'error': 'app_check_unavailable'});
      }
      final token = request.headers['x-firebase-appcheck'];
      if (token == null || token.isEmpty) {
        return _json(401, {'error': 'app_check_required'});
      }
      try {
        await verifier.verify(token);
      } on AppCheckException {
        // No detail to the caller: a probing client learns nothing about why.
        return _json(401, {'error': 'app_check_invalid'});
      } catch (_) {
        return _json(401, {'error': 'app_check_invalid'});
      }
    }

    // Read with a hard byte ceiling — Content-Length is client-asserted, so
    // the stream is counted as it arrives rather than trusted up front.
    final declared = request.contentLength;
    if (declared != null && declared > config.maxBodyBytes) {
      return _json(413, {'error': 'body_too_large'});
    }
    final bodyBuilder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      bodyBuilder.add(chunk);
      if (bodyBuilder.length > config.maxBodyBytes) {
        return _json(413, {'error': 'body_too_large'});
      }
    }

    // ---- reserve the slot BEFORE spending money (§1) ---------------------
    // Parallel batch items cannot overshoot a nearly-empty cap this way, and
    // the refund below is what keeps "a failed extraction is 0 rescues" true.
    final ReservationOutcome slot;
    try {
      slot = await usage.reserve(bucketKey);
    } catch (_) {
      // The ledger is down. Fail CLOSED: an unmetered extraction is exactly
      // the hole this whole file exists to shut.
      return _json(503, {'error': 'quota_unavailable'});
    }
    if (!slot.allowed) {
      return switch (slot.denyReason) {
        'rate_limited' =>
          _json(429, {'error': 'rate_limited', 'quota': slot.toJson()}),
        // Not out of allowance — out of TODAY's. The message has to say so, or
        // a user who has 1100 rescues left reads this as the cap and churns.
        'daily_limit' => _json(429, {
            'error': 'daily_limit',
            'message': "That's today's limit for rescuing recipes — "
                'your allowance is untouched and it resets tomorrow.',
            'quota': slot.toJson(),
          }),
        // Honest, not blaming the user: the breaker is our ceiling, not theirs.
        'globally_busy' => _json(503, {
            'error': 'busy',
            'message': 'Extraction is busy right now — please try again later.',
          }),
        'voided' => _json(403, {'error': 'voided'}),
        _ => _json(429, {'error': 'cap_exceeded', 'quota': slot.toJson()}),
      };
    }

    final http.Response upstreamResp;
    try {
      upstreamResp = await upstream
          .post(
            Uri.parse(
                '${config.upstreamBase}/v1beta/models/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': config.geminiApiKey,
            },
            body: bodyBuilder.takeBytes(),
          )
          .timeout(config.upstreamTimeout);
    } on TimeoutException {
      await _refund(usage, bucketKey, slot);
      return _json(504, {'error': 'upstream_timeout'});
    } on Exception {
      // No detail passthrough: upstream error strings could carry the key.
      await _refund(usage, bucketKey, slot);
      return _json(502, {'error': 'upstream_unreachable'});
    }

    // An upstream refusal is our problem, not the user's allowance. 4xx that
    // the CLIENT caused (a malformed request) still counts as nothing spent:
    // Gemini bills on generation, and there was none.
    if (upstreamResp.statusCode >= 400) {
      await _refund(usage, bucketKey, slot);
      return Response(upstreamResp.statusCode,
          body: upstreamResp.bodyBytes,
          headers: {'Content-Type': 'application/json'});
    }

    // Success: hand the balance back with the content so the app's counter is
    // current without a second call (§2). A body we cannot parse is passed
    // through untouched rather than dropped.
    return Response(
      upstreamResp.statusCode,
      body: _withQuota(upstreamResp.bodyBytes, slot),
      headers: {'Content-Type': 'application/json'},
    );
  };
}

Future<void> _refund(
    UsageLedger usage, String bucketKey, ReservationOutcome slot) async {
  final bucket = slot.bucket;
  if (bucket == null) return;
  try {
    await usage.refund(bucketKey, bucket);
  } catch (_) {} // best-effort by contract — never mask the real failure
}

/// Adds `"quota": {...}` to Gemini's JSON object response. Anything that is
/// not a JSON object comes back byte-for-byte.
List<int> _withQuota(Uint8List body, ReservationOutcome slot) {
  try {
    final decoded = jsonDecode(utf8.decode(body));
    if (decoded is! Map<String, dynamic>) return body;
    decoded['quota'] = slot.toJson();
    return utf8.encode(jsonEncode(decoded));
  } catch (_) {
    return body;
  }
}
