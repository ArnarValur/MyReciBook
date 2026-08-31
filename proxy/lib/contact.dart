// The website's contact form, server side.
//
// Lives in the extraction proxy rather than a service of its own: it is one
// route, it needs the same Cloud Run deploy and the same Secret Manager, and
// a second service would be a second cold start to pay for. Nothing here
// touches the ledger, the Gemini key or App Check — a contact message is not
// an extraction, and must never spend a rescue.
//
// Mail goes out through Brevo's transactional API: FROM the authenticated
// myrecibook.com sender, TO our own inbox, with the visitor in Reply-To so
// hitting reply answers the person, not ourselves.

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

/// What a browser may send us and from where. The form is public, so every
/// bound here is a spend ceiling as much as a validation rule.
class ContactConfig {
  const ContactConfig({
    required this.brevoApiKey,
    required this.fromEmail,
    required this.fromName,
    required this.toEmail,
    required this.allowedOrigins,
    this.maxBodyBytes = 16 * 1024,
    this.maxPerHourPerIp = 5,
    this.minFillSeconds = 3,
  });

  final String brevoApiKey;
  final String fromEmail;
  final String fromName;
  final String toEmail;

  /// Exact origins allowed to POST here. Empty = allow any, which is only
  /// ever right in local development.
  final Set<String> allowedOrigins;

  final int maxBodyBytes;
  final int maxPerHourPerIp;

  /// A form returned faster than this was not typed by a person.
  final int minFillSeconds;
}

/// Field ceilings. Generous for a human, ruinous for a link-spam payload.
const _maxName = 120;
const _maxEmail = 200;
const _maxMessage = 4000;

final _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

Response _json(int status, Map<String, Object?> body, Map<String, String> cors) =>
    Response(status,
        body: jsonEncode(body),
        headers: {'Content-Type': 'application/json', ...cors});

/// Fixed-window counter, per remote address, held in memory.
///
/// Deliberately not Firestore: a contact form is not billing, the window is
/// an hour, and Cloud Run runs at most a handful of instances — the worst
/// case is a determined sender getting maxPerHour per instance instead of
/// per service. That is still a wall, and it costs nothing to run.
class _IpWindow {
  final Map<String, (int windowStart, int count)> _hits = {};

  bool allow(String ip, int limit, DateTime now) {
    final hour = now.toUtc().millisecondsSinceEpoch ~/ 3600000;
    final seen = _hits[ip];
    if (seen == null || seen.$1 != hour) {
      // Sweep on write; the map only ever holds one hour of callers.
      _hits.removeWhere((_, v) => v.$1 != hour);
      _hits[ip] = (hour, 1);
      return true;
    }
    if (seen.$2 >= limit) return false;
    _hits[ip] = (hour, seen.$2 + 1);
    return true;
  }
}

/// Handles OPTIONS and POST on /contact. Returns null for anything else so
/// the caller can fall through to its own routing.
class ContactHandler {
  ContactHandler(this.config, {http.Client? client, DateTime Function()? now})
      : _client = client ?? http.Client(),
        _now = now ?? DateTime.now;

  final ContactConfig config;
  final http.Client _client;
  final DateTime Function() _now;
  final _window = _IpWindow();

  Map<String, String> _cors(Request request) {
    final origin = request.headers['origin'];
    if (origin == null) return const {};
    final ok = config.allowedOrigins.isEmpty ||
        config.allowedOrigins.contains(origin);
    if (!ok) return const {};
    return {
      'Access-Control-Allow-Origin': origin,
      'Vary': 'Origin',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Max-Age': '3600',
    };
  }

  Future<Response>? maybeHandle(Request request) {
    if (request.url.path != 'contact') return null;
    if (request.method == 'OPTIONS') {
      final cors = _cors(request);
      // No CORS headers back = origin not on the list; the browser blocks it.
      return Future.value(Response(204, headers: cors));
    }
    if (request.method != 'POST') return null;
    return _post(request);
  }

  Future<Response> _post(Request request) async {
    final cors = _cors(request);
    final origin = request.headers['origin'];
    if (origin != null && cors.isEmpty) {
      return _json(403, {'error': 'origin_not_allowed'}, const {});
    }

    final declared = request.contentLength;
    if (declared != null && declared > config.maxBodyBytes) {
      return _json(413, {'error': 'body_too_large'}, cors);
    }

    final Map<String, Object?> body;
    try {
      final raw = await request.readAsString();
      if (raw.length > config.maxBodyBytes) {
        return _json(413, {'error': 'body_too_large'}, cors);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) throw const FormatException();
      body = decoded;
    } catch (_) {
      return _json(400, {'error': 'bad_request'}, cors);
    }

    // ---- the spam traps, re-checked here ---------------------------------
    // The page runs the same two checks, but a bot that posts straight to this
    // URL never executes the page's JavaScript. Client-side checks are a
    // courtesy to humans; these are the ones that count.
    //
    // Both answer 200 "sent". A bot told it was blocked simply tries again
    // with the trap field removed.
    final trap = (body['company'] as String?) ?? '';
    if (trap.trim().isNotEmpty) {
      return _json(200, {'ok': true}, cors);
    }
    final elapsedMs = body['elapsedMs'];
    if (elapsedMs is! num || elapsedMs < config.minFillSeconds * 1000) {
      return _json(200, {'ok': true}, cors);
    }

    final name = ((body['name'] as String?) ?? '').trim();
    final email = ((body['email'] as String?) ?? '').trim();
    final message = ((body['message'] as String?) ?? '').trim();
    if (name.length < 2 || name.length > _maxName) {
      return _json(400, {'error': 'invalid_name'}, cors);
    }
    if (email.length > _maxEmail || !_emailShape.hasMatch(email)) {
      return _json(400, {'error': 'invalid_email'}, cors);
    }
    if (message.length < 5 || message.length > _maxMessage) {
      return _json(400, {'error': 'invalid_message'}, cors);
    }
    // A header cannot hold a newline; refusing beats sanitising, because the
    // only sender who wants one is building an injected header.
    if (name.contains('\n') || name.contains('\r') || email.contains('\n')) {
      return _json(400, {'error': 'invalid_name'}, cors);
    }

    // Cloud Run puts the real client first in X-Forwarded-For and appends its
    // own hops; the leftmost entry is the one to count.
    final ip = (request.headers['x-forwarded-for']?.split(',').first.trim()) ??
        'unknown';
    if (!_window.allow(ip, config.maxPerHourPerIp, _now())) {
      return _json(429, {'error': 'too_many_messages'}, cors);
    }

    try {
      final resp = await _client
          .post(
            Uri.parse('https://api.brevo.com/v3/smtp/email'),
            headers: {
              'api-key': config.brevoApiKey,
              'Content-Type': 'application/json',
              'accept': 'application/json',
            },
            body: jsonEncode({
              'sender': {'email': config.fromEmail, 'name': config.fromName},
              'to': [
                {'email': config.toEmail}
              ],
              // Reply goes to the visitor, not back to ourselves.
              'replyTo': {'email': email, 'name': name},
              'subject': 'MyReciBook contact — $name',
              'textContent': '$message\n\n— $name ($email)',
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return _json(200, {'ok': true}, cors);
      }
      // Brevo's body can echo the address back; keep it out of the log.
      return _json(502, {'error': 'send_failed'}, cors);
    } catch (_) {
      return _json(502, {'error': 'send_failed'}, cors);
    }
  }
}
