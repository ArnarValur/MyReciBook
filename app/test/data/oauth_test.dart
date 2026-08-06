// OAuthFlow against a fake auth channel + MockClient: the browser is a
// captured launchUrl, the redirect is a pushed 'onAuthRedirect' message.
// The PKCE loop is closed end-to-end: hashing the verifier the flow POSTs
// must reproduce the challenge it launched with.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/oauth.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fake-auth-test');
  const codec = StandardMethodCodec();
  late List<String> launched;

  setUp(() {
    launched = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'launchUrl':
          launched.add(call.arguments as String);
          return null;
        case 'takePendingRedirects':
          return <String>[];
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> pushRedirect(String uri) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(channel.name,
            codec.encodeMethodCall(MethodCall('onAuthRedirect', uri)), (_) {});
  }

  MockClient tokenClient(Map<String, dynamic> json,
          {int status = 200, void Function(http.Request)? capture}) =>
      MockClient((req) async {
        capture?.call(req);
        return http.Response(jsonEncode(json), status,
            headers: {'content-type': 'application/json'});
      });

  test('PKCE challenge matches RFC 7636 appendix B vector', () {
    expect(
      pkceChallenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
  });

  test('placeholder client id → NotConfiguredException, browser untouched',
      () async {
    final flow = OAuthFlow(channel: channel, client: tokenClient(const {}));
    await expectLater(
      flow.begin(OAuthProvider.googleDrive('placeholder-drive-client')),
      throwsA(isA<NotConfiguredException>()),
    );
    expect(launched, isEmpty);
  });

  test('google happy path: auth url shape, redirect, token POST shape',
      () async {
    late http.Request tokenReq;
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient({
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'expires_in': 3600,
      }, capture: (r) => tokenReq = r),
    );
    final future =
        flow.begin(OAuthProvider.googleDrive('gid-1.apps.googleusercontent.com'));
    await pumpEventQueue();

    final auth = Uri.parse(launched.single);
    expect(auth.scheme, 'https');
    expect(auth.host, 'accounts.google.com');
    expect(auth.path, '/o/oauth2/v2/auth');
    final q = auth.queryParameters;
    expect(q['response_type'], 'code');
    expect(q['client_id'], 'gid-1.apps.googleusercontent.com');
    expect(q['redirect_uri'], 'com.merkurialstudio.myrecibook://oauth2');
    expect(q['scope'], 'https://www.googleapis.com/auth/drive.file');
    expect(q['access_type'], 'offline');
    expect(q['prompt'], 'consent');
    expect(q['code_challenge_method'], 'S256');
    expect(q['code_challenge'], hasLength(43));
    final state = q['state']!;
    expect(state.length, greaterThanOrEqualTo(22)); // 16 random bytes

    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?code=c0de&state=$state');
    final tokens = await future;

    expect(tokens.accessToken, 'at-1');
    expect(tokens.refreshToken, 'rt-1');
    final secs = tokens.expiresAt!.difference(DateTime.now()).inSeconds;
    expect(secs, inInclusiveRange(3590, 3600));
    expect(tokens.isExpired, isFalse);

    expect(tokenReq.method, 'POST');
    expect(tokenReq.url.toString(), 'https://oauth2.googleapis.com/token');
    expect(tokenReq.headers['content-type'],
        startsWith('application/x-www-form-urlencoded'));
    final body = Uri.splitQueryString(tokenReq.body);
    expect(body['grant_type'], 'authorization_code');
    expect(body['code'], 'c0de');
    expect(body['redirect_uri'], 'com.merkurialstudio.myrecibook://oauth2');
    expect(body['client_id'], 'gid-1.apps.googleusercontent.com');
    // PKCE loop closes: hashed POSTed verifier == launched challenge.
    expect(pkceChallenge(body['code_verifier']!), q['code_challenge']);
  });

  test('dropbox auth url: no scope param, token_access_type=offline', () async {
    final flow = OAuthFlow(channel: channel, client: tokenClient(const {}));
    final future = flow.begin(OAuthProvider.dropbox('appkey-1'));
    await pumpEventQueue();

    final auth = Uri.parse(launched.single);
    expect(auth.host, 'www.dropbox.com');
    expect(auth.path, '/oauth2/authorize');
    final q = auth.queryParameters;
    expect(q.containsKey('scope'), isFalse);
    expect(q['token_access_type'], 'offline');
    expect(q['client_id'], 'appkey-1');

    // Kill the pending flow so no timer outlives the test. Listener must
    // attach before the push — the error fires during the redirect await.
    final done = expectLater(future, throwsA(isA<OAuthException>()));
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?error=access_denied');
    await done;
  });

  test('state mismatch → typed rejection, no token request', () async {
    var posted = false;
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient(const {}, capture: (_) => posted = true),
    );
    final future = flow.begin(OAuthProvider.dropbox('appkey-1'));
    await pumpEventQueue();

    final done = expectLater(
      future,
      throwsA(predicate(
          (e) => e is OAuthException && e.message.contains('state'))),
    );
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?code=c0de&state=WRONG');
    await done;
    expect(posted, isFalse);
  });

  test('error param in redirect → typed provider error', () async {
    final flow = OAuthFlow(channel: channel, client: tokenClient(const {}));
    final future = flow.begin(OAuthProvider.dropbox('appkey-1'));
    await pumpEventQueue();
    final state = Uri.parse(launched.single).queryParameters['state']!;

    final done = expectLater(
      future,
      throwsA(predicate(
          (e) => e is OAuthException && e.message.contains('access_denied'))),
    );
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?error=access_denied&state=$state');
    await done;
  });

  test('second begin() cancels the first', () async {
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient(const {'access_token': 'at-2'}),
    );
    final first = flow.begin(OAuthProvider.dropbox('appkey-1'));
    await pumpEventQueue();
    final second = flow.begin(OAuthProvider.dropbox('appkey-1'));
    await expectLater(first, throwsA(isA<AuthCancelledException>()));
    await pumpEventQueue();

    // Second flow still completes normally with its own state.
    final state = Uri.parse(launched[1]).queryParameters['state']!;
    await pushRedirect(
        'com.merkurialstudio.myrecibook://oauth2?code=c2&state=$state');
    expect((await second).accessToken, 'at-2');
  });

  test('no redirect → AuthTimeoutException, never a hang', () async {
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient(const {}),
      timeout: const Duration(milliseconds: 30),
    );
    await expectLater(
      flow.begin(OAuthProvider.dropbox('appkey-1')),
      throwsA(isA<AuthTimeoutException>()),
    );
  });

  test('utf8 token body without charset survives (rule 7)', () async {
    final flow = OAuthFlow(
      channel: channel,
      client: MockClient((_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'access_token': 'tökén-½'})), 200)),
    );
    final refreshed = await flow.refresh(OAuthProvider.dropbox('appkey-1'),
        const TokenSet(accessToken: 'old', refreshToken: 'rt'));
    expect(refreshed.accessToken, 'tökén-½');
  });

  test('refresh happy path: grant shape, keeps old refresh token', () async {
    late http.Request req;
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient({'access_token': 'at-new', 'expires_in': 14400},
          capture: (r) => req = r),
    );
    final refreshed = await flow.refresh(OAuthProvider.dropbox('appkey-1'),
        const TokenSet(accessToken: 'at-old', refreshToken: 'rt-1'));

    expect(req.url.toString(), 'https://api.dropboxapi.com/oauth2/token');
    final body = Uri.splitQueryString(req.body);
    expect(body['grant_type'], 'refresh_token');
    expect(body['refresh_token'], 'rt-1');
    expect(body['client_id'], 'appkey-1');
    expect(refreshed.accessToken, 'at-new');
    expect(refreshed.refreshToken, 'rt-1'); // provider omitted it → keep old
    expect(refreshed.expiresAt, isNotNull);
  });

  test('refresh invalid_grant → AuthRevokedException', () async {
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient(const {'error': 'invalid_grant'}, status: 400),
    );
    await expectLater(
      flow.refresh(OAuthProvider.googleDrive('gid-1'),
          const TokenSet(accessToken: 'at', refreshToken: 'rt')),
      throwsA(isA<AuthRevokedException>()),
    );
  });

  test('refresh 401 → AuthRevokedException', () async {
    final flow = OAuthFlow(
      channel: channel,
      client: tokenClient(const {}, status: 401),
    );
    await expectLater(
      flow.refresh(OAuthProvider.dropbox('appkey-1'),
          const TokenSet(accessToken: 'at', refreshToken: 'rt')),
      throwsA(isA<AuthRevokedException>()),
    );
  });

  test('refresh without a refresh token → AuthRevokedException', () async {
    final flow = OAuthFlow(channel: channel, client: tokenClient(const {}));
    await expectLater(
      flow.refresh(OAuthProvider.dropbox('appkey-1'),
          const TokenSet(accessToken: 'at')),
      throwsA(isA<AuthRevokedException>()),
    );
  });
}
