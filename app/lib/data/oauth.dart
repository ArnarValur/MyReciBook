// OAuth 2.0 authorization-code + PKCE (RFC 7636) for the storage connectors
// (arch §4: the user's folder is the later sync surface). Public client — no
// secret in the APK, the S256 challenge is the protection. The browser is the
// system one via AuthBridge; the redirect returns on
// com.merkurialstudio.myrecibook://oauth2 as an 'onAuthRedirect' push.
// clientId values starting 'placeholder-' fail fast so the UI can show the
// honest unconfigured state until real credentials land.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'sha256.dart';

/// Base of every auth failure; the subtypes are what callers branch on.
class OAuthException implements Exception {
  final String message;

  const OAuthException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Client id is still a 'placeholder-*' value — connector not configured yet.
class NotConfiguredException extends OAuthException {
  const NotConfiguredException(super.message);
}

/// A newer begin() superseded this flow (user retried the connect).
class AuthCancelledException extends OAuthException {
  const AuthCancelledException(super.message);
}

/// No redirect within the timeout — user abandoned the browser.
class AuthTimeoutException extends OAuthException {
  const AuthTimeoutException(super.message);
}

/// Grant revoked upstream (401 / invalid_grant) — user must re-connect.
class AuthRevokedException extends OAuthException {
  const AuthRevokedException(super.message);
}

/// Access + optional refresh token; JSON round-trips for the token store.
class TokenSet {
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  const TokenSet({required this.accessToken, this.refreshToken, this.expiresAt});

  /// Expired or expiring within 60 s — refresh before use. Null expiry never
  /// expires client-side; the API's own 401 is the fallback signal.
  bool get isExpired =>
      expiresAt != null &&
      DateTime.now().isAfter(expiresAt!.subtract(const Duration(seconds: 60)));

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        if (refreshToken != null) 'refresh_token': refreshToken,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };

  factory TokenSet.fromJson(Map<String, dynamic> json) {
    final access = json['access_token'];
    if (access is! String || access.isEmpty) {
      throw const FormatException('missing access_token');
    }
    final expires = json['expires_at'];
    return TokenSet(
      accessToken: access,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: expires is String ? DateTime.tryParse(expires) : null,
    );
  }
}

/// Endpoint + client config for one storage provider. The redirect
/// scheme://host must match AuthBridge's manifest intent-filter.
class OAuthProvider {
  static const defaultRedirectUri = 'com.merkurialstudio.myrecibook://oauth2';

  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String clientId;
  final String redirectUri;
  final List<String> scopes;
  final Map<String, String> extraAuthParams;
  final Map<String, String> extraTokenParams;

  const OAuthProvider({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.clientId,
    this.redirectUri = defaultRedirectUri,
    this.scopes = const [],
    this.extraAuthParams = const {},
    this.extraTokenParams = const {},
  });

  /// Real credentials pending — begin() refuses with NotConfiguredException.
  bool get isPlaceholder => clientId.startsWith('placeholder-');

  /// drive.file scope: only files this app creates — the folder stays theirs.
  static OAuthProvider googleDrive(String clientId) => OAuthProvider(
        authorizationEndpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
        tokenEndpoint: 'https://oauth2.googleapis.com/token',
        clientId: clientId,
        // Google POLICY (S21 400 invalid_request, 2026-08-09): an installed
        // app's custom redirect scheme MUST be the reversed client id — the
        // package-name scheme is rejected even with "custom URI scheme"
        // enabled on the client. AuthBridge routes any
        // com.googleusercontent.apps.* redirect; the manifest needs one
        // <data> entry per Android client (i.e. per signing cert).
        redirectUri: '${reversedClientScheme(clientId)}:/oauth2redirect',
        scopes: const ['https://www.googleapis.com/auth/drive.file'],
        // Google mints a refresh token only with offline access + forced consent.
        extraAuthParams: const {'access_type': 'offline', 'prompt': 'consent'},
      );

  /// 'N-x.apps.googleusercontent.com' → 'com.googleusercontent.apps.N-x'.
  static String reversedClientScheme(String clientId) {
    const suffix = '.apps.googleusercontent.com';
    final stem = clientId.endsWith(suffix)
        ? clientId.substring(0, clientId.length - suffix.length)
        : clientId;
    return 'com.googleusercontent.apps.$stem';
  }

  /// App-folder scoping lives in the Dropbox app registration, not a scope.
  static OAuthProvider dropbox(String appKey) => OAuthProvider(
        authorizationEndpoint: 'https://www.dropbox.com/oauth2/authorize',
        tokenEndpoint: 'https://api.dropboxapi.com/oauth2/token',
        clientId: appKey,
        // token_access_type=offline is Dropbox's refresh-token switch.
        extraAuthParams: const {'token_access_type': 'offline'},
      );
}

/// S256 (RFC 7636 §4.2): base64url(sha256(ascii(verifier))), unpadded.
String pkceChallenge(String verifier) =>
    base64Url.encode(sha256(ascii.encode(verifier))).replaceAll('=', '');

class OAuthFlow {
  OAuthFlow({
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/auth'),
    http.Client? client,
    Random? random,
    this.timeout = const Duration(minutes: 5),
  })  : _client = client ?? http.Client(),
        _random = random ?? Random.secure() {
    channel.setMethodCallHandler(_handle);
  }

  final MethodChannel channel;
  final Duration timeout;
  final http.Client _client;
  final Random _random;

  _Pending? _pending;

  /// Launches the system browser, waits for the oauth2 redirect, exchanges
  /// the code. Every exit is typed: NotConfigured / Cancelled / Timeout /
  /// OAuthException — never a hang.
  Future<TokenSet> begin(OAuthProvider provider) async {
    if (provider.isPlaceholder) {
      throw NotConfiguredException(
          '${provider.clientId}: real credentials not wired yet');
    }
    // A cold-start redirect has no surviving verifier — drain and discard.
    try {
      await channel.invokeMethod<List<dynamic>>('takePendingRedirects');
    } catch (_) {}

    _pending?.fail(const AuthCancelledException('superseded by a newer sign-in'));
    final state = _randomToken(16);
    final verifier = _randomToken(32); // 43 chars — RFC 7636 §4.1 minimum
    final pending = _Pending();
    _pending = pending;

    final authUri = Uri.parse(provider.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': provider.clientId,
        'redirect_uri': provider.redirectUri,
        if (provider.scopes.isNotEmpty) 'scope': provider.scopes.join(' '),
        'state': state,
        'code_challenge': pkceChallenge(verifier),
        'code_challenge_method': 'S256',
        ...provider.extraAuthParams,
      },
    );

    try {
      await channel.invokeMethod<void>('launchUrl', authUri.toString());
    } catch (e) {
      _clear(pending);
      throw OAuthException('browser launch failed: $e');
    }
    pending.timer = Timer(
        timeout,
        () =>
            pending.fail(const AuthTimeoutException('no redirect before timeout')));

    final String redirect;
    try {
      redirect = await pending.completer.future;
    } finally {
      _clear(pending);
    }

    final code = _extractCode(redirect, state);
    return _tokenRequest(provider, {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': provider.redirectUri,
      'client_id': provider.clientId,
      'code_verifier': verifier,
      ...provider.extraTokenParams,
    });
  }

  /// Refresh-token grant (same form-encoded shape for Google and Dropbox).
  /// A missing/rejected refresh token is AuthRevokedException → re-connect.
  Future<TokenSet> refresh(OAuthProvider provider, TokenSet tokens) async {
    final rt = tokens.refreshToken;
    if (rt == null || rt.isEmpty) {
      throw const AuthRevokedException('no refresh token stored');
    }
    return _tokenRequest(
      provider,
      {
        'grant_type': 'refresh_token',
        'refresh_token': rt,
        'client_id': provider.clientId,
        ...provider.extraTokenParams,
      },
      keepRefreshToken: rt,
      refreshing: true,
    );
  }

  // Never throws — an error reply would leave the uri queued on the bridge.
  Future<Object?> _handle(MethodCall call) async {
    if (call.method != 'onAuthRedirect') return null;
    final uri = call.arguments;
    if (uri is String) _pending?.complete(uri); // no pending flow → stale, drop
    return null;
  }

  String _extractCode(String redirect, String expectedState) {
    final Uri uri;
    try {
      uri = Uri.parse(redirect);
    } catch (_) {
      throw const OAuthException('unparseable redirect');
    }
    final q = uri.queryParameters;
    final error = q['error'];
    if (error != null && error.isNotEmpty) {
      throw OAuthException('provider error: $error');
    }
    if (q['state'] != expectedState) {
      throw const OAuthException('state mismatch — redirect rejected');
    }
    final code = q['code'];
    if (code == null || code.isEmpty) {
      throw const OAuthException('redirect missing code');
    }
    return code;
  }

  Future<TokenSet> _tokenRequest(
    OAuthProvider provider,
    Map<String, String> fields, {
    String? keepRefreshToken,
    bool refreshing = false,
  }) async {
    final http.Response resp;
    try {
      // Map body → application/x-www-form-urlencoded (both providers require it)
      resp = await _client.post(Uri.parse(provider.tokenEndpoint), body: fields);
    } catch (e) {
      throw OAuthException('token request failed: $e');
    }
    final body = utf8.decode(resp.bodyBytes, allowMalformed: true); // rule 7
    if (resp.statusCode != 200) {
      final error = _errorField(body);
      if (refreshing && (resp.statusCode == 401 || error == 'invalid_grant')) {
        throw AuthRevokedException('refresh rejected: ${error ?? resp.statusCode}');
      }
      throw OAuthException(
          'token endpoint ${resp.statusCode}: ${error ?? _snippet(body)}');
    }
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw const OAuthException('token endpoint returned non-JSON');
    }
    final access = json['access_token'];
    if (access is! String || access.isEmpty) {
      throw const OAuthException('token response missing access_token');
    }
    final rawExpires = json['expires_in'];
    final seconds = rawExpires is int
        ? rawExpires
        : rawExpires is String
            ? int.tryParse(rawExpires)
            : null;
    return TokenSet(
      accessToken: access,
      // Providers may omit refresh_token on refresh — keep the stored one.
      refreshToken: json['refresh_token'] as String? ?? keepRefreshToken,
      expiresAt:
          seconds == null ? null : DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  String? _errorField(String body) {
    try {
      final json = jsonDecode(body);
      return json is Map ? json['error'] as String? : null;
    } catch (_) {
      return null;
    }
  }

  String _snippet(String body) =>
      body.length <= 120 ? body : body.substring(0, 120);

  String _randomToken(int bytes) {
    final b = List<int>.generate(bytes, (_) => _random.nextInt(256));
    return base64Url.encode(b).replaceAll('=', '');
  }

  void _clear(_Pending pending) {
    pending.timer?.cancel();
    if (identical(_pending, pending)) _pending = null;
  }
}

class _Pending {
  final Completer<String> completer = Completer<String>();
  Timer? timer;

  void complete(String uri) {
    timer?.cancel();
    if (!completer.isCompleted) completer.complete(uri);
  }

  void fail(OAuthException e) {
    timer?.cancel();
    if (!completer.isCompleted) completer.completeError(e);
  }
}
