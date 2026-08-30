// Fair-use counter state (docs/ai-cap-mechanics.md §2): the last `quota`
// object the proxy sent, cached so the card has a true number at cold start
// instead of waiting for this session's first extraction.
//
// Same shape as ByokModel — pure op → notify → best-effort persist — and the
// same store: device.json. A counter is keyed to THIS install's install id,
// so it must never ride cloud backup onto a second phone and claim spending
// that phone never did.

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../domain/quota.dart';

class QuotaModel extends ChangeNotifier {
  QuotaModel({AppSettings? settings})
      : _settings = settings,
        _quota = QuotaSnapshot.fromJson(settings?.quota);

  final AppSettings? _settings;
  QuotaSnapshot? _quota;

  /// Null = the proxy has never answered on this install (fresh install, or
  /// BYOK from the start). The card then says so instead of showing a 0 it
  /// cannot stand behind.
  QuotaSnapshot? get quota => _quota;

  /// The sink GeminiExtractor hands every proxy answer's numbers to.
  Future<void> record(QuotaSnapshot quota) async {
    _quota = quota;
    notifyListeners();
    try {
      await _settings?.setQuota(quota.toJson());
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
