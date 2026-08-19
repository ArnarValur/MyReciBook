import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook_proxy/proxy.dart';
import 'package:myrecibook_proxy/usage_counter.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _model = 'gemini-3.5-flash-lite';
const _path = 'v1beta/models/$_model:generateContent';

Request _post(String path,
        {Map<String, String> headers = const {'x-install-id': 'test-install-0001'},
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

  Handler handler({ProxyConfig? config, UsageCounter? counter}) =>
      buildHandler(config ?? const ProxyConfig(geminiApiKey: 'srv-key'),
          client: fakeUpstream, counter: counter);

  test('forwards the extraction call; key travels as header, never in URL',
      () async {
    final resp = await handler()(_post(_path));
    expect(resp.statusCode, 200);
    expect(await resp.readAsString(), '{"candidates":[]}');
    final sent = upstreamCalls.single;
    expect(sent.headers['x-goog-api-key'], 'srv-key');
    expect(sent.url.toString(), isNot(contains('key=')));
    expect(sent.url.path, '/v1beta/models/$_model:generateContent');
    expect(sent.body, '{"contents":[]}');
  });

  test('healthz answers without touching upstream', () async {
    final resp =
        await handler()(Request('GET', Uri.parse('http://localhost/healthz')));
    expect(resp.statusCode, 200);
    expect(upstreamCalls, isEmpty);
  });

  test('non-POST and unknown paths are refused', () async {
    final get = await handler()(Request('GET', Uri.parse('http://localhost/$_path')));
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

  test('missing or malformed install id is refused', () async {
    final missing = await handler()(_post(_path, headers: {}));
    expect(missing.statusCode, 400);
    final malformed = await handler()(
        _post(_path, headers: {'x-install-id': 'no spaces allowed!'}));
    expect(malformed.statusCode, 400);
    expect(upstreamCalls, isEmpty);
  });

  test('cap: request N+1 in the same month gets 429 with the cap stated',
      () async {
    final h = handler(
        config: const ProxyConfig(geminiApiKey: 'k', monthlyCapPerInstall: 2));
    expect((await h(_post(_path))).statusCode, 200);
    expect((await h(_post(_path))).statusCode, 200);
    final over = await h(_post(_path));
    expect(over.statusCode, 429);
    expect(jsonDecode(await over.readAsString()),
        {'error': 'cap_exceeded', 'cap': 2});
    expect(upstreamCalls, hasLength(2));
  });

  test('cap resets on UTC month rollover and is per-install', () async {
    var now = DateTime.utc(2026, 8, 9);
    final counter = InMemoryUsageCounter(now: () => now);
    final h = handler(
        config: const ProxyConfig(geminiApiKey: 'k', monthlyCapPerInstall: 1),
        counter: counter);
    expect((await h(_post(_path))).statusCode, 200);
    expect((await h(_post(_path))).statusCode, 429);
    expect(
        (await h(_post(_path, headers: {'x-install-id': 'other-install-0002'})))
            .statusCode,
        200);
    now = DateTime.utc(2026, 9, 1);
    expect((await h(_post(_path))).statusCode, 200);
  });

  test('oversized body is refused before upstream sees it', () async {
    final h = handler(
        config: const ProxyConfig(geminiApiKey: 'k', maxBodyBytes: 10));
    final resp = await h(_post(_path, body: '{"data":"0123456789ABCDEF"}'));
    expect(resp.statusCode, 413);
    expect(upstreamCalls, isEmpty);
  });

  test('upstream errors pass through as status + body (client maps them)',
      () async {
    fakeUpstream = MockClient(
        (req) async => http.Response('{"error":{"code":429}}', 429));
    final resp = await handler()(_post(_path));
    expect(resp.statusCode, 429);
    expect(await resp.readAsString(), '{"error":{"code":429}}');
  });

  test('unreachable upstream becomes a clean 502, no detail leak', () async {
    fakeUpstream = MockClient((req) async => throw http.ClientException('x'));
    final resp = await handler()(_post(_path));
    expect(resp.statusCode, 502);
    expect(jsonDecode(await resp.readAsString()),
        {'error': 'upstream_unreachable'});
  });
}
