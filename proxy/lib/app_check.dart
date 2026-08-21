// Firebase App Check verification (audit B1, §3 layer 8).
//
// The hole this closes: the proxy's only gate was X-Install-Id, a header the
// CLIENT mints. The proxy URL ships compiled into the APK and `strings` finds
// it in seconds, so anyone could loop fresh UUIDs and spend Gemini on Arnar's
// card — unmetered, because a fresh id is a fresh bucket.
//
// App Check makes the DEVICE prove itself: Play Integrity attests that the
// caller is the real app on a real Android device, Firebase mints a short-
// lived JWT, and this file verifies that JWT against Google's public JWKS.
// A scripted caller has no attestation and therefore no token.
//
// Enforcement is behind a flag (APP_CHECK_ENFORCE) so the proxy can deploy and
// be smoke-tested before the app that carries tokens exists. Flipping it is
// ONE line in the runbook. When enforced it fails CLOSED.

import 'dart:async';

import 'package:jose/jose.dart';

/// Verified facts from an App Check token. Only the app id is interesting;
/// everything else has already been checked by the time this exists.
class AppCheckClaims {
  const AppCheckClaims({required this.appId, required this.expiresAt});

  /// `sub` — the Firebase app id the token was minted for.
  final String appId;
  final DateTime expiresAt;
}

class AppCheckException implements Exception {
  const AppCheckException(this.message);
  final String message;
  @override
  String toString() => 'AppCheckException: $message';
}

/// Verifies App Check JWTs for one Firebase project.
///
/// The JWKS is fetched lazily and cached by the `jose` key store; Google
/// rotates those keys rarely and publishes them well ahead of use.
class AppCheckVerifier {
  AppCheckVerifier({
    required this.projectNumber,
    required this.projectId,
    JsonWebKeyStore? keyStore,
  }) : _keys = keyStore ?? _defaultKeyStore();

  /// The NUMERIC project number (not the project id) — App Check puts it in
  /// `iss` and `aud`. Both appear in the Firebase console's project settings.
  final String projectNumber;

  /// The project id, e.g. gen-lang-client-0166122901. Google has shipped both
  /// forms in `aud` over time, so either is accepted.
  final String projectId;

  final JsonWebKeyStore _keys;

  static const jwksUri = 'https://firebaseappcheck.googleapis.com/v1/jwks';

  static JsonWebKeyStore _defaultKeyStore() =>
      JsonWebKeyStore()..addKeySetUrl(Uri.parse(jwksUri));

  /// Throws [AppCheckException] on anything that is not a currently valid
  /// token for this project. Never returns a partially-checked result.
  Future<AppCheckClaims> verify(String token) async {
    final JsonWebSignature jws;
    try {
      jws = JsonWebSignature.fromCompactSerialization(token);
    } catch (_) {
      throw const AppCheckException('malformed token');
    }
    // Header check BEFORE signature work: App Check signs RS256 and nothing
    // else, so refusing other algorithms here closes the "alg: none" family
    // of tricks rather than trusting the library to.
    final alg = jws.commonHeader.algorithm;
    if (alg != 'RS256') {
      throw AppCheckException('unexpected algorithm: $alg');
    }

    final JsonWebToken jwt;
    try {
      jwt = await JsonWebToken.decodeAndVerify(token, _keys);
    } catch (e) {
      throw AppCheckException('signature not verified: $e');
    }

    final claims = jwt.claims;
    final iss = claims['iss'];
    if (iss != 'https://firebaseappcheck.googleapis.com/$projectNumber') {
      throw AppCheckException('wrong issuer: $iss');
    }
    final aud = claims['aud'];
    final audiences = aud is List
        ? aud.map((a) => '$a').toList()
        : (aud == null ? const <String>[] : ['$aud']);
    if (!audiences.contains('projects/$projectNumber') &&
        !audiences.contains('projects/$projectId')) {
      throw AppCheckException('wrong audience: $audiences');
    }
    final exp = claims['exp'];
    final expiresAt = exp is int
        ? DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true)
        : null;
    if (expiresAt == null || expiresAt.isBefore(DateTime.now().toUtc())) {
      throw const AppCheckException('token expired');
    }
    final sub = claims['sub'];
    if (sub is! String || sub.isEmpty) {
      throw const AppCheckException('token has no subject');
    }
    return AppCheckClaims(appId: sub, expiresAt: expiresAt);
  }
}
