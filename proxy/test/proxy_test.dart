import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook_proxy/app_check.dart';
import 'package:myrecibook_proxy/proxy.dart';
import 'package:myrecibook_proxy/usage_counter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _model = 'gemini-3.5-flash-lite';
const _path = 'v1beta/models/$_model:generateContent';

Request _post(String path,
        {Map<String, String> headers = const {
          'x-install-id': 'test-install-0001'
        },
        String body = '{"contents":[]}'}) =>
    Request('POST', Uri.parse('http://localhost/$path'),
        headers: headers, body: body);

void main() {
  late List<http.Request> upstreamCalls;
  late http.Client fakeUpstream;

  setUp(() {
    upstreamCalls = [];
    fakeUpstream = MockClient((req) async {
      upstreamCalls.add(req);
      return http.Response('{"candidates":[]}', 200,
          headers: {'content-type': 'application/json'});
    });
  });

  Handler handler(
          {ProxyConfig? config,
          UsageLedger? ledger,
          AppCheckVerifier? appCheck}) =>
      buildHandler(config ?? const ProxyConfig(geminiApiKey: 'srv-key'),
          client: fakeUpstream, ledger: ledger, appCheck: appCheck);

  test('forwards the extraction call; key travels as header, never in URL',
      () async {
    final resp = await handler()(_post(_path));
    expect(resp.statusCode, 200);
    final sent = upstreamCalls.single;
    expect(sent.headers['x-goog-api-key'], 'srv-key');
    expect(sent.url.toString(), isNot(contains('key=')));
    expect(sent.url.path, '/v1beta/models/$_model:generateContent');
    expect(sent.body, '{"contents":[]}');
  });

  test('a success carries the quota balance back for the counter UI', () async {
    final resp = await handler()(_post(_path));
    final body = jsonDecode(await resp.readAsString()) as Map<String, dynamic>;
    expect(body['candidates'], isEmpty, reason: 'upstream content untouched');
    final quota = body['quota'] as Map<String, dynamic>;
    expect(quota['cap'], kDefaultIncludedCap);
    expect(quota, contains('used'));
    // Nothing resets (Decision 1) — the wire contract must not carry a date
    // that lets any UI promise a refill.
    expect(quota, isNot(contains('resets_at')));
  });

  test('health answers without touching upstream', () async {
    // /health is the real one — Cloud Run's frontend swallows /healthz — but
    // both must answer so a local caller using either still works.
    for (final path in ['health', 'healthz']) {
      final resp = await handler()(
          Request('GET', Uri.parse('http://localhost/$path')));
      expect(resp.statusCode, 200, reason: '/$path should answer');
    }
    expect(upstreamCalls, isEmpty);
  });

  test('non-POST and unknown paths are refused', () async {
    final get =
        await handler()(Request('GET', Uri.parse('http://localhost/$_path')));
    expect(get.statusCode, 405);
    final wrong = await handler()(_post('v1beta/models/$_model:countTokens'));
    expect(wrong.statusCode, 404);
    expect(upstreamCalls, isEmpty);
  });

  test('model outside the allowlist is refused — leaked URL is not a free key',
      () async {
    final resp =
        await handler()(_post('v1beta/models/gemini-3.6-pro:generateContent'));
    expect(resp.statusCode, 403);
    expect(upstreamCalls, isEmpty);
  });

  test('missing or malformed bucket key is refused', () async {
    final missing = await handler()(_post(_path, headers: {}));
    expect(missing.statusCode, 400);
    final malformed = await handler()(
        _post(_path, headers: {'x-install-id': 'no spaces allowed!'}));
    expect(malformed.statusCode, 400);
    expect(upstreamCalls, isEmpty);
  });

  // The free fortnight is the OFFER (Arnar, 2026-08-21): first two weeks free,
  // then 1200 over the year. Spending inside it is free but never unrecorded —
  // it lands in graceUsed, so total usage is always graceUsed + used.
  group('the free fortnight', () {
    test('spends grace, not the cap, inside the window', () async {
      var now = DateTime.utc(2026, 8, 21);
      final h = handler(
          ledger: InMemoryUsageLedger(
              cap: 2, now: () => now, graceDays: 14, perDayLimit: 100));
      // Well past cap 2, and still allowed — the cap is not biting yet.
      for (var i = 0; i < 5; i++) {
        expect((await h(_post(_path))).statusCode, 200);
      }
      final resp = await h(_post(_path));
      final quota = jsonDecode(await resp.readAsString())['quota'];
      expect(quota['used'], 0, reason: 'the year allowance is untouched');
      expect(quota['grace_used'], 6, reason: 'free, but counted');
    });

    test('the cap starts biting when the fortnight ends', () async {
      var now = DateTime.utc(2026, 8, 21);
      final h = handler(
          ledger: InMemoryUsageLedger(cap: 1, now: () => now, graceDays: 14));
      expect((await h(_post(_path))).statusCode, 200); // free
      now = DateTime.utc(2026, 9, 10); // day 20 — window closed
      expect((await h(_post(_path))).statusCode, 200); // the 1 included
      expect((await h(_post(_path))).statusCode, 429); // now it bites
    });

    test('grace has a quiet ceiling, then falls through — never a hard stop',
        () async {
      final h = handler(
          ledger: InMemoryUsageLedger(
              cap: 1000,
              perMinuteLimit: 100000,
              perDayLimit: 100000,
              graceDays: 14));
      for (var i = 0; i < kGraceCeiling + 1; i++) {
        expect((await h(_post(_path))).statusCode, 200);
      }
      final resp = await h(_post(_path));
      final quota = jsonDecode(await resp.readAsString())['quota'];
      expect(quota['grace_used'], kGraceCeiling);
      expect(quota['used'], greaterThan(0),
          reason: 'past the ceiling it falls through to normal counting');
    });
  });

  // graceDays: 0 in this group so the cap itself is what is under test.
  group('the cap', () {
    test('request N+1 gets 429 with the balance stated', () async {
      final h = handler(ledger: InMemoryUsageLedger(cap: 2, graceDays: 0));
      expect((await h(_post(_path))).statusCode, 200);
      expect((await h(_post(_path))).statusCode, 200);
      final over = await h(_post(_path));
      expect(over.statusCode, 429);
      final body = jsonDecode(await over.readAsString());
      expect(body['error'], 'cap_exceeded');
      expect(body['quota']['cap'], 2);
      expect(upstreamCalls, hasLength(2), reason: 'no spend past the cap');
    });

    test('is per bucket, and NEVER refills — not even years later', () async {
      var now = DateTime.utc(2026, 8, 21);
      final h = handler(
          ledger: InMemoryUsageLedger(cap: 1, now: () => now, graceDays: 0));
      expect((await h(_post(_path))).statusCode, 200);
      expect((await h(_post(_path))).statusCode, 429);
      // A different buyer has their own allowance.
      expect(
          (await h(_post(_path,
                  headers: {'x-install-id': 'other-install-0002'})))
              .statusCode,
          200);
      // Decision 1: the grant is once, forever. An anniversary — or five —
      // changes nothing; an empty grant stays empty until a top-up.
      now = DateTime.utc(2031, 8, 22);
      expect((await h(_post(_path))).statusCode, 429);
    });

    // The guarantee from §1: "a failed extraction is 0 rescues".
    test('a failed extraction is refunded, not charged', () async {
      fakeUpstream = MockClient((_) async => throw http.ClientException('x'));
      final ledger = InMemoryUsageLedger(cap: 1, graceDays: 0);
      final h = handler(ledger: ledger);
      expect((await h(_post(_path))).statusCode, 502);
      // The slot came back, so the next real call still fits under cap 1.
      fakeUpstream = MockClient((req) async {
        upstreamCalls.add(req);
        return http.Response('{"candidates":[]}', 200);
      });
      expect((await handler(ledger: ledger)(_post(_path))).statusCode, 200);
    });

    test('an upstream 4xx/5xx is refunded too — Gemini generated nothing',
        () async {
      fakeUpstream =
          MockClient((_) async => http.Response('{"error":{"code":500}}', 500));
      final ledger = InMemoryUsageLedger(cap: 1, graceDays: 0);
      expect((await handler(ledger: ledger)(_post(_path))).statusCode, 500);
      fakeUpstream = MockClient((_) async => http.Response('{"ok":1}', 200));
      expect((await handler(ledger: ledger)(_post(_path))).statusCode, 200);
    });
  });

  group('abuse layers', () {
    // Arnar's catch, 2026-08-21: the free fortnight must not be drainable.
    test('per-bucket daily ceiling applies DURING the free fortnight',
        () async {
      var now = DateTime.utc(2026, 8, 21, 9);
      final h = handler(
          ledger: InMemoryUsageLedger(
              cap: 1000,
              perMinuteLimit: 100000,
              perDayLimit: 3,
              graceDays: 14,
              now: () => now));
      for (var i = 0; i < 3; i++) {
        expect((await h(_post(_path))).statusCode, 200);
      }
      final blocked = await h(_post(_path));
      expect(blocked.statusCode, 429);
      final body = jsonDecode(await blocked.readAsString());
      expect(body['error'], 'daily_limit');
      // The wording must not read as "you are out of rescues".
      expect(body['message'], contains('resets tomorrow'));
      expect(body['quota']['used'], 0, reason: 'the year is untouched');
      // Tomorrow it opens again — a governor, never a hard stop.
      now = DateTime.utc(2026, 8, 22, 9);
      expect((await h(_post(_path))).statusCode, 200);
    });

    test('a failed extraction gives the day slot back too', () async {
      fakeUpstream = MockClient((_) async => throw http.ClientException('x'));
      final ledger = InMemoryUsageLedger(perDayLimit: 1, graceDays: 0);
      expect((await handler(ledger: ledger)(_post(_path))).statusCode, 502);
      fakeUpstream = MockClient((_) async => http.Response('{"ok":1}', 200));
      expect((await handler(ledger: ledger)(_post(_path))).statusCode, 200);
    });

    test('per-bucket rate limit answers 429 rate_limited', () async {
      final h = handler(
          ledger: InMemoryUsageLedger(
              cap: 1000, perMinuteLimit: 3, graceDays: 0));
      for (var i = 0; i < 3; i++) {
        expect((await h(_post(_path))).statusCode, 200);
      }
      final limited = await h(_post(_path));
      expect(limited.statusCode, 429);
      expect(jsonDecode(await limited.readAsString())['error'], 'rate_limited');
      expect(upstreamCalls, hasLength(3));
    });

    test('global daily breaker answers an honest busy, not a user-blaming cap',
        () async {
      final h = handler(
          ledger: InMemoryUsageLedger(
              cap: 1000,
              perMinuteLimit: 1000,
              globalDailyLimit: 2,
              graceDays: 0));
      expect((await h(_post(_path))).statusCode, 200);
      expect((await h(_post(_path))).statusCode, 200);
      // A DIFFERENT bucket still hits the global ceiling.
      final busy =
          await h(_post(_path, headers: {'x-install-id': 'other-install-0002'}));
      expect(busy.statusCode, 503);
      final body = jsonDecode(await busy.readAsString());
      expect(body['error'], 'busy');
      expect(body['message'], contains('try again later'));
    });
  });

  group('app check', () {
    test('enforced with no token is refused before any spend', () async {
      // A verifier IS wired here — the refusal must come from the missing
      // token, not from the proxy being unconfigured.
      final h = handler(
          config: const ProxyConfig(geminiApiKey: 'k', appCheckEnforced: true),
          appCheck:
              AppCheckVerifier(projectNumber: '1', projectId: 'test-project'));
      final resp = await h(_post(_path));
      expect(resp.statusCode, 401);
      expect(jsonDecode(await resp.readAsString())['error'],
          'app_check_required');
      expect(upstreamCalls, isEmpty);
    });

    test('enforced but unconfigured fails CLOSED, never open', () async {
      final h = handler(
          config: const ProxyConfig(
              geminiApiKey: 'k', appCheckEnforced: true));
      final resp = await h(_post(_path,
          headers: const {
            'x-install-id': 'test-install-0001',
            'x-firebase-appcheck': 'whatever',
          }));
      // No verifier wired → 503, and nothing reaches Gemini.
      expect(resp.statusCode, 503);
      expect(upstreamCalls, isEmpty);
    });

    test('not enforced lets the closed track run without tokens', () async {
      expect((await handler()(_post(_path))).statusCode, 200);
    });
  });

  test('oversized body is refused before upstream sees it', () async {
    final h =
        handler(config: const ProxyConfig(geminiApiKey: 'k', maxBodyBytes: 10));
    final resp = await h(_post(_path, body: '{"data":"0123456789ABCDEF"}'));
    expect(resp.statusCode, 413);
    expect(upstreamCalls, isEmpty);
  });

  test('unreachable upstream becomes a clean 502, no detail leak', () async {
    fakeUpstream = MockClient((req) async => throw http.ClientException('x'));
    final resp = await handler()(_post(_path));
    expect(resp.statusCode, 502);
    expect(
        jsonDecode(await resp.readAsString()), {'error': 'upstream_unreachable'});
  });

  test('a ledger that is down fails CLOSED — never an unmetered extraction',
      () async {
    final resp = await handler(ledger: _BrokenLedger())(_post(_path));
    expect(resp.statusCode, 503);
    expect(jsonDecode(await resp.readAsString())['error'], 'quota_unavailable');
    expect(upstreamCalls, isEmpty);
  });
}

class _BrokenLedger implements UsageLedger {
  @override
  Future<bool> globalBreakerTripped() async => false;
  @override
  Future<ReservationOutcome> reserve(String key) async =>
      throw StateError('firestore down');
  @override
  Future<void> refund(String key, QuotaBucket bucket) async {}
}
