// One road for every uncaught error (audit H1, 2026-08-21).
//
// Before: PlatformDispatcher.onError returned true and the error stopped dead
// in the local ring buffer — invisible to anything outside the long-press door
// on the Settings version footer. An invisible crash is a crash nobody fixes.
//
// Now every error takes the same road:
//   1. the local ring buffer, ALWAYS — offline, no consent needed, and it is
//      what the in-app door copies out;
//   2. the remote sink, when the user has crash reporting on — the dashboard
//      that Play Console vitals reads;
//   3. onward to the platform: FlutterError.presentError for the framework's
//      own dump, and `false` from PlatformDispatcher.onError, meaning NOT
//      handled, so the VM's default handler still logs it.
//
// Read the layering honestly: returning false stops the SWALLOW, it does not
// by itself put a Dart error into Play vitals — Flutter does not kill the
// process for an uncaught Dart exception, so Android never records a crash.
// The remote sink is what makes a crash visible off-device. Both layers are
// needed; neither is sufficient alone.

import 'crash_log.dart';

/// Crash reporting default — ON. Arnar decided 2026-08-22: shipping it dormant
/// meant a tester could hit a bug and we would learn nothing, which defeats the
/// point of having it during a closed test.
///
/// The switch in Settings still lets anyone turn it off, and everything
/// uploaded is scrubbed first (see [scrubForUpload]) — no recipe text, no
/// paths, no tokens. The local ring buffer runs regardless of this setting.
///
/// This is the default for fresh installs only; anyone who has already touched
/// the switch keeps their own choice.
const bool kCrashReportingDefaultOn = true;

/// The off-device destination for an error. Implemented by the Crashlytics
/// sink; left null in tests and in any build without Firebase configured.
abstract class CrashSink {
  /// [error] arrives as an already-scrubbed STRING, not the original object:
  /// an arbitrary exception can hold recipe text in fields no scrubber can
  /// reach, so the reporter flattens and cleans it first. Same for
  /// [breadcrumbs] — the recent ring-buffer content, oldest first, which is
  /// what a bare stack trace never shows. A sink must not scrub again.
  Future<void> send(
    String error,
    StackTrace? stack, {
    String? context,
    required bool fatal,
    required List<String> breadcrumbs,
  });

  /// Mirrors the user's toggle into the sink's own collection switch, so a
  /// disabled sink also stops buffering on disk.
  Future<void> setEnabled(bool enabled);
}

/// Fans one error out to the local log and (when enabled) the remote sink.
/// Never throws: reporting an error must not be able to raise another one.
class CrashReporter {
  // Named parameters cannot start with an underscore in Dart, so an
  // initializing formal (`this._log`) is not available for private fields
  // behind a named API — the lint's suggestion does not compile here.
  // ignore_for_file: prefer_initializing_formals
  CrashReporter({
    required CrashLog log,
    CrashSink? sink,
    bool enabled = false,
  })  : _log = log,
        _sink = sink,
        _enabled = enabled;

  final CrashLog _log;
  final CrashSink? _sink;

  bool _enabled;

  /// How much recent history rides along with a report. Small on purpose —
  /// breadcrumbs are for the last few moves, not the whole session.
  static const int _breadcrumbCount = 10;

  bool get enabled => _enabled;

  /// Whether this build has anywhere to send a report at all. False when no
  /// Firebase project is configured (no google-services.json), which is the
  /// normal state of a fresh clone — the Settings row says so instead of
  /// offering a switch that would quietly do nothing.
  bool get hasSink => _sink != null;

  /// Called by the Settings toggle. Turning it off stops uploads immediately
  /// and tells the sink to drop whatever it had buffered.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    try {
      await _sink?.setEnabled(value);
    } catch (_) {} // a failing sink must not break the settings screen
  }

  /// The single entry point both error hooks call. [fatal] separates a crash
  /// from a caught-and-reported problem in the remote dashboard.
  void record(Object error, StackTrace? stack,
      {String? context, bool fatal = true}) {
    // Local first and unconditionally: it is the only layer that works
    // offline, and the only one that needs no consent.
    _log.record(error, stack, context: context);
    if (!_enabled) return;
    final sink = _sink;
    if (sink == null) return;
    try {
      // Fire-and-forget: the hook must return promptly, and a slow upload
      // must never stall the frame that is already going wrong.
      sink
          .send(
            scrubForUpload('$error'),
            stack,
            context: context == null ? null : scrubForUpload(context),
            fatal: fatal,
            breadcrumbs: _breadcrumbs(),
          )
          .catchError((_) {}); // an upload failure is not an error to report
    } catch (_) {}
  }

  /// Ring-buffer lines, oldest first, already scrubbed.
  List<String> _breadcrumbs() {
    try {
      // CrashLog.entries is newest first; breadcrumbs read better oldest first.
      final recent = _log.entries.take(_breadcrumbCount).toList().reversed;
      return [
        for (final e in recent)
          scrubForUpload('${e['at']} · ${e['context'] ?? ''} · ${e['error']}'),
      ];
    } catch (_) {
      return const [];
    }
  }
}

// What must never ride an upload. The local log lives on the user's own device
// and only redacts the Gemini key; anything LEAVING the device is held to the
// stricter bar, because an error string is exactly where recipe content leaks.
final _uploadScrubbers = <(RegExp, String Function(Match))>[
  // Secrets, in every shape they reach an error string.
  (RegExp(r'key=[A-Za-z0-9_\-]+'), (_) => 'key=…'),
  (RegExp(r'Bearer\s+[A-Za-z0-9._\-]+'), (_) => 'Bearer …'),
  (
    RegExp(r'"(access_token|refresh_token)"\s*:\s*"[^"]*"'),
    (m) => '"${m.group(1)}":"…"',
  ),
  // A recipe file path carries the recipe TITLE in its basename, and a SAF
  // document id carries the user's folder layout. Keep the shape, drop the
  // name — "/…/….json" still says a recipe file was what failed.
  (
    RegExp(r'(?:/[^/\s]+)+\.(json|jpg|jpeg|png|pdf)'),
    (m) => '/…/….${m.group(1)}',
  ),
  (RegExp(r'content://[^\s)"]+'), (_) => 'content://…'),
];

/// Strips secrets and user content out of a string bound for the remote sink.
/// Deliberately blunt — over-redacting costs one debugging detail,
/// under-redacting ships somebody's recipe to a dashboard.
String scrubForUpload(String s) {
  var out = s;
  for (final (pattern, replace) in _uploadScrubbers) {
    out = out.replaceAllMapped(pattern, replace);
  }
  return out;
}
