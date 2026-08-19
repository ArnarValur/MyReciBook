// Thin extraction proxy (D2, senior review F3).
//
// A transparent relay for the ONE Gemini call the app makes
// (models/<model>:generateContent). The client keeps building the request it
// already speaks (spike-proven shape, assembled in
// app/lib/data/gemini_extractor.dart); this proxy's whole job is:
//   1. hold GEMINI_API_KEY server-side — it never ships in the APK and never
//      rides a URL (goes upstream as the x-goog-api-key header);
//   2. refuse anything that is not the extraction call (POST, allowlisted
//      model, bounded body) so a leaked proxy URL is not a general Gemini key;
//   3. count per-install usage for the stated fair-use cap
//      (context.md constraint 2/3) — the one piece of state allowed.
// Request bodies are forwarded, never stored, never logged.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

import 'usage_counter.dart';

class ProxyConfig {
  const ProxyConfig({
    required this.geminiApiKey,
    this.allowedModels = const {'gemini-3.5-flash-lite'},
    this.monthlyCapPerInstall = 100,
    this.maxBodyBytes = 25 * 1024 * 1024,
    this.upstreamBase = 'https://generativelanguage.googleapis.com',
    this.upstreamTimeout = const Duration(seconds: 150),
  });

  final String geminiApiKey;
  final Set<String> allowedModels;

  /// Fair-use backstop per install per UTC month. Strawman default — the
  /// listed cap number is Arnar's call (pulse: cap counter 4d); override with
  /// env FREE_MONTHLY_CAP at deploy time.
  final int monthlyCapPerInstall;

  /// Several screenshots per recipe, base64-inflated ~1.33x. 25 MB clears a
  /// worst-case batch; anything bigger is not a recipe.
  final int maxBodyBytes;

  final String upstreamBase;

  /// Slightly above the client's own 120 s timeout so the client, not the
  /// proxy, decides when to give up.
  final Duration upstreamTimeout;
}

/// Matches app-generated install ids (UUID-ish); rejects junk before it can
/// become a counter key.
final _installIdShape = RegExp(r'^[A-Za-z0-9-]{8,64}$');

final _pathShape = RegExp(r'^v1beta/models/([A-Za-z0-9.-]+):generateContent$');

Response _json(int status, Map<String, Object?> body) => Response(status,
    body: jsonEncode(body), headers: {'Content-Type': 'application/json'});

Handler buildHandler(ProxyConfig config,
    {http.Client? client, UsageCounter? counter}) {
  final upstream = client ?? http.Client();
  final usage = counter ?? InMemoryUsageCounter();

  return (Request request) async {
    if (request.method == 'GET' && request.url.path == 'healthz') {
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
    final installId = request.headers['x-install-id'];
    if (installId == null || !_installIdShape.hasMatch(installId)) {
      return _json(400, {'error': 'missing_install_id'});
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

    final count = await usage.increment(installId);
    if (count > config.monthlyCapPerInstall) {
      return _json(429, {
        'error': 'cap_exceeded',
        'cap': config.monthlyCapPerInstall,
      });
    }

    final http.Response upstreamResp;
    try {
      upstreamResp = await upstream
          .post(
            Uri.parse('${config.upstreamBase}/v1beta/models/$model:generateContent'),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': config.geminiApiKey,
            },
            body: bodyBuilder.takeBytes(),
          )
          .timeout(config.upstreamTimeout);
    } on TimeoutException {
      return _json(504, {'error': 'upstream_timeout'});
    } on Exception {
      // No detail passthrough: upstream error strings could carry the key.
      return _json(502, {'error': 'upstream_unreachable'});
    }

    return Response(upstreamResp.statusCode,
        body: upstreamResp.bodyBytes,
        headers: {'Content-Type': 'application/json'});
  };
}
