// The Settings switch for sending crash reports off the device (audit H1).
// Same D3 shape as ThemeModel/UnitsModel: pure state flip → notify →
// best-effort persist, plus one extra hop the others don't have — the live
// CrashReporter is told immediately, so turning the switch off stops uploads
// on the spot instead of at next launch.
//
// Inert (no settings, no reporter — the buildApp test seam's default) it
// reports the compiled-in default and changes nothing.

import 'package:flutter/foundation.dart';

import '../data/app_settings.dart';
import '../data/crash_reporter.dart';

class CrashReportingModel extends ChangeNotifier {
  // Private fields behind a named API — see the note in crash_reporter.dart.
  // ignore_for_file: prefer_initializing_formals
  CrashReportingModel({AppSettings? settings, CrashReporter? reporter})
      : _settings = settings,
        _reporter = reporter,
        _enabled = settings?.crashReportingEnabled ?? kCrashReportingDefaultOn;

  final AppSettings? _settings;
  final CrashReporter? _reporter;

  bool _enabled;

  bool get enabled => _enabled;

  /// True when this build actually has somewhere to send reports. False means
  /// no Firebase is configured, and the row says so rather than offering a
  /// switch that would quietly do nothing.
  bool get hasSink => _reporter?.hasSink ?? false;

  /// Fires one deliberate report so the pipe can be SEEN working — the
  /// Crashlytics dashboard shows nothing at all until a first report lands,
  /// which is indistinguishable from being broken. Non-fatal: it is a probe,
  /// not a crash, so it does not pollute the crash-free-users number.
  ///
  /// Returns false when there is nothing to send through (reporting off, or
  /// no Firebase in this build) so the caller can say so honestly.
  bool sendTestReport() {
    final reporter = _reporter;
    if (reporter == null || !reporter.hasSink || !_enabled) return false;
    reporter.record(
      Exception('Test report from MyReciBook settings — not a real crash'),
      StackTrace.current,
      context: 'sent by hand from the error log',
      fatal: false,
    );
    return true;
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    // Reporter first: it is what actually stops or starts uploading.
    await _reporter?.setEnabled(value);
    try {
      await _settings?.setCrashReportingEnabled(value);
    } catch (_) {} // persistence best-effort — in-memory state already live
  }
}
