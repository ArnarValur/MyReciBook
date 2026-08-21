// The app's half of Firebase App Check (audit B1).
//
// What it buys: the proxy stops trusting X-Install-Id — a header this app
// simply makes up — and starts requiring proof that the caller is really
// MyReciBook on a real Android device. Play Integrity attests, Firebase mints
// a short-lived JWT, the proxy verifies it against Google's public keys.
// Without this, anyone who pulls the proxy URL out of the APK spends Gemini
// on Arnar's card.
//
// Deliberately the only file besides crashlytics_sink.dart that imports
// Firebase, and it degrades the same way: no Firebase configured (no
// google-services.json) → no token → the header is simply absent. That is
// correct while the proxy runs with APP_CHECK_ENFORCE=false, and it is
// exactly what must change before the enforcement flip.

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Supplies App Check tokens for outgoing proxy calls.
///
/// Tokens are cached by the Firebase SDK and refreshed well before expiry, so
/// calling [token] per request is cheap — no round trip in the common case.
class AppCheckTokens {
  AppCheckTokens._(this._appCheck);

  final FirebaseAppCheck _appCheck;

  /// The header the proxy reads. Matches `x-firebase-appcheck` server-side.
  static const header = 'X-Firebase-AppCheck';

  /// Activates App Check, or returns null when this build has no Firebase.
  ///
  /// Debug builds use the debug provider: it prints a token to logcat that has
  /// to be pasted into Firebase console → App Check → Manage debug tokens,
  /// otherwise a debug build cannot pass enforcement. Release builds attest
  /// through Play Integrity, which needs the app to come from Play — a
  /// sideloaded release build will NOT get a token.
  static Future<AppCheckTokens?> activate() async {
    try {
      final instance = FirebaseAppCheck.instance;
      await instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      return AppCheckTokens._(instance);
    } catch (e) {
      // No Firebase, no Play services, no network at boot — all the same
      // answer: no attestation available, carry on without the header.
      debugPrint('App Check not available: $e');
      return null;
    }
  }

  /// A current token, or null if one cannot be obtained right now. Null is not
  /// fatal while the proxy is unenforced; once enforced it means the call will
  /// be refused, which is the intended behavior for an unattested caller.
  Future<String?> token() async {
    try {
      return await _appCheck.getToken();
    } catch (e) {
      debugPrint('App Check token unavailable: $e');
      return null;
    }
  }
}
