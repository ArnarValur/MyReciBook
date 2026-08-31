import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook_proxy/contact.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _origin = 'https://myrecibook.com';

ContactConfig _config() => const ContactConfig(
      brevoApiKey: 'test-key',
      fromEmail: 'noreply@myrecibook.com',
      fromName: 'MyReciBook',
      toEmail: 'inbox@example.com',
      allowedOrigins: {_origin},
    );

/// Records what would have gone to Brevo; answers 201 like the real API.
class _Outbox {
  final List<Map<String, Object?>> sent = [];
  late final http.Client client = MockClient((req) async {
    sent.add(jsonDecode(req.body) as Map<String, Object?>);
    return http.Response('{"messageId":"1"}', 201);
  });
}

Request _post(Map<String, Object?> body, {String? origin = _origin}) => Request(
      'POST',
      Uri.parse('https://proxy.test/contact'),
      headers: {
        'Content-Type': 'application/json',
        if (origin != null) 'origin': origin,
        'x-forwarded-for': '203.0.113.7, 10.0.0.1',
      },
      body: jsonEncode(body),
    );

Map<String, Object?> _good({Map<String, Object?> overrides = const {}}) => {
      'name': 'Arnar',
      'email': 'someone@example.com',
      'message': 'The pantry shelf will not fold.',
      'company': '',
      'elapsedMs': 9000,
      ...overrides,
    };

void main() {
  test('a real message is mailed, with the visitor as reply-to', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler.maybeHandle(_post(_good()))!;

    expect(resp.statusCode, 200);
    expect(outbox.sent, hasLength(1));
    final mail = outbox.sent.single;
    expect((mail['sender'] as Map)['email'], 'noreply@myrecibook.com');
    expect((mail['to'] as List).single, {'email': 'inbox@example.com'});
    expect((mail['replyTo'] as Map)['email'], 'someone@example.com');
    expect(mail['textContent'], contains('pantry shelf'));
    // The address stays readable in the body, not only in Reply-To.
    expect(mail['textContent'], contains('(someone@example.com)'));
  });

  test('a filled honeypot is answered ok but never sent', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler
        .maybeHandle(_post(_good(overrides: {'company': 'Acme SEO'})))!;

    // 200 on purpose: telling a bot it was caught only helps it retry.
    expect(resp.statusCode, 200);
    expect(outbox.sent, isEmpty);
  });

  test('a form returned too fast is answered ok but never sent', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp =
        await handler.maybeHandle(_post(_good(overrides: {'elapsedMs': 40})))!;

    expect(resp.statusCode, 200);
    expect(outbox.sent, isEmpty);
  });

  test('a missing elapsedMs is treated as a bot, not as zero', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);
    final body = _good()..remove('elapsedMs');

    final resp = await handler.maybeHandle(_post(body))!;

    expect(resp.statusCode, 200);
    expect(outbox.sent, isEmpty);
  });

  test('a junk email is refused', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler
        .maybeHandle(_post(_good(overrides: {'email': 'not-an-address'})))!;

    expect(resp.statusCode, 400);
    expect(outbox.sent, isEmpty);
  });

  test('a newline in the name is refused, not sanitised', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler.maybeHandle(
        _post(_good(overrides: {'name': 'Arnar\nBcc: victim@example.com'})))!;

    expect(resp.statusCode, 400);
    expect(outbox.sent, isEmpty);
  });

  test('an oversized message is refused', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler
        .maybeHandle(_post(_good(overrides: {'message': 'x' * 5000})))!;

    expect(resp.statusCode, 400);
    expect(outbox.sent, isEmpty);
  });

  test('a foreign origin is refused outright', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    final resp = await handler
        .maybeHandle(_post(_good(), origin: 'https://evil.example'))!;

    expect(resp.statusCode, 403);
    expect(outbox.sent, isEmpty);
  });

  test('the sixth message from one address in an hour is refused', () async {
    final outbox = _Outbox();
    final handler = ContactHandler(_config(), client: outbox.client);

    for (var i = 0; i < 5; i++) {
      expect((await handler.maybeHandle(_post(_good()))!).statusCode, 200);
    }
    final sixth = await handler.maybeHandle(_post(_good()))!;

    expect(sixth.statusCode, 429);
    expect(outbox.sent, hasLength(5));
  });

  test('preflight answers with the allowed origin', () async {
    final handler = ContactHandler(_config(), client: _Outbox().client);
    final resp = await handler.maybeHandle(Request(
      'OPTIONS',
      Uri.parse('https://proxy.test/contact'),
      headers: {'origin': _origin},
    ))!;

    expect(resp.statusCode, 204);
    expect(resp.headers['access-control-allow-origin'], _origin);
  });

  test('other paths are left to the extraction routing', () {
    final handler = ContactHandler(_config(), client: _Outbox().client);
    final other = Request('POST',
        Uri.parse('https://proxy.test/v1beta/models/x:generateContent'));

    expect(handler.maybeHandle(other), isNull);
  });
}
