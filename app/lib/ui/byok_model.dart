// BYOK — bring your own Gemini key (mvp-build plan, agreed 2026-08-30).
// A buyer's perk: AI runs on their key and their Google bill, exits the
// fair-use counter entirely. UnitsModel shape: pure op → notify → best-effort
// persist. The key lives in device.json (never rides backup); at-rest
// encryption joins tokens.json in the pre-prod keystore hardening.
// GATE (open): "behind the unlock" waits for the billing seam — until it
// exists, dev builds show BYOK to everyone.

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';

class ByokModel extends ChangeNotifier {
  ByokModel({AppSettings? settings})
      : _settings = settings,
        _key = settings?.byokKey;

  final AppSettings? _settings;
  String? _key;

  /// The user's Gemini API key; null = proxy mode (our key, our counter).
  String? get key => _key;

  bool get active => _key != null;

  /// Empty/whitespace clears — same gesture as Remove.
  Future<void> setKey(String? key) async {
    final k = (key ?? '').trim();
    final v = k.isEmpty ? null : k;
    if (v == _key) return;
    _key = v;
    notifyListeners();
    try {
      await _settings?.setByokKey(v);
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
