// App Check claim validation (audit B1). These are the checks that stand
// between the proxy and an unmetered Gemini bill, so each failure mode gets
// its own test rather than one happy path.
//
// A locally generated RSA key stands in for Google's JWKS: the point under
// test is the CLAIM logic — issuer, audience, expiry, algorithm — not
// Google's key rotation.

import 'package:jose/jose.dart';
import 'package:myrecibook_proxy/app_check.dart';
import 'package:test/test.dart';

const _projectNumber = '213431165631';
const _projectId = 'gen-lang-client-0166122901';

late JsonWebKey signingKey;
late JsonWebKeyStore store;

String mintToken({
  String? issuer,
  Object? audience,
  String subject = '1:213431165631:android:abc123',
  Duration expiresIn = const Duration(hours: 1),
}) {
  final builder = JsonWebSignatureBuilder()
    ..jsonContent = {
      'iss': issuer ??
          'https://firebaseappcheck.googleapis.com/$_projectNumber',
      'aud': audience ?? ['projects/$_projectNumber'],
      'sub': subject,
      'exp': DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000,
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    }
    ..addRecipient(signingKey, algorithm: 'RS256')
    ..setProtectedHeader('typ', 'JWT');
  return builder.build().toCompactSerialization();
}

void main() {
  setUpAll(() {
    signingKey = JsonWebKey.generate('RS256');
    store = JsonWebKeyStore()..addKey(signingKey);
  });

  AppCheckVerifier verifier() => AppCheckVerifier(
        projectNumber: _projectNumber,
        projectId: _projectId,
        keyStore: store,
      );

  test('a well-formed token for this project verifies', () async {
    final claims = await verifier().verify(mintToken());
    expect(claims.appId, '1:213431165631:android:abc123');
    expect(claims.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
  });

  test('accepts the project-id audience form too', () async {
    final claims =
        await verifier().verify(mintToken(audience: ['projects/$_projectId']));
    expect(claims.appId, isNotEmpty);
  });

  test('rejects a token minted for a DIFFERENT project', () async {
    // The attack this stops: anyone can create their own Firebase project and
    // get real, Google-signed App Check tokens from it.
    await expectLater(
      verifier().verify(mintToken(
          issuer: 'https://firebaseappcheck.googleapis.com/999999',
          audience: ['projects/999999'])),
      throwsA(isA<AppCheckException>()),
    );
  });

  test('rejects a right-issuer/wrong-audience token', () async {
    await expectLater(
      verifier().verify(mintToken(audience: ['projects/999999'])),
      throwsA(isA<AppCheckException>()),
    );
  });

  test('rejects an expired token', () async {
    await expectLater(
      verifier().verify(mintToken(expiresIn: const Duration(seconds: -10))),
      throwsA(isA<AppCheckException>()),
    );
  });

  test('rejects a token signed by a key we do not trust', () async {
    final rogue = JsonWebKey.generate('RS256');
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'iss': 'https://firebaseappcheck.googleapis.com/$_projectNumber',
        'aud': ['projects/$_projectNumber'],
        'sub': 'forged',
        'exp': DateTime.now()
                .add(const Duration(hours: 1))
                .millisecondsSinceEpoch ~/
            1000,
      }
      ..addRecipient(rogue, algorithm: 'RS256');
    await expectLater(
      verifier().verify(builder.build().toCompactSerialization()),
      throwsA(isA<AppCheckException>()),
    );
  });

  test('rejects garbage rather than throwing something untyped', () async {
    await expectLater(
        verifier().verify('not-a-jwt'), throwsA(isA<AppCheckException>()));
    await expectLater(verifier().verify(''), throwsA(isA<AppCheckException>()));
  });
}
