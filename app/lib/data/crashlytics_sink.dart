// The remote half of crash reporting (audit H1 · scratchpad install recipe).
//
// Deliberately the ONLY file that imports Firebase. Everything else talks to
// the CrashSink interface, so a build with no Firebase configured — no
// google-services.json, which is a Console download only Arnar can make —
// simply gets a null sink and keeps working on the local ring buffer alone.
//
// Nothing here decides WHETHER to upload. CrashReporter owns that, from the
// user's Settings toggle; this file only knows how to send.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter.dart';

/// A live Crashlytics sink, or null when this build has no Firebase project
/// wired. Never throws: a missing or broken Firebase config must degrade to
/// "no remote reporting", never to a boot failure.
Future<CrashSink?> buildCrashSink() async {
  try {
    // Reads android/app/google-services.json through the generated resources.
    // Absent → this throws, and a null sink is the correct, quiet answer.
    await Firebase.initializeApp();
    return CrashlyticsSink(FirebaseCrashlytics.instance);
  } catch (e) {
    debugPrint('Crashlytics not configured, local crash log only: $e');
    return null;
  }
}

class CrashlyticsSink implements CrashSink {
  CrashlyticsSink(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> setEnabled(bool enabled) =>
      // Off also drops whatever Crashlytics had buffered on disk, so turning
      // the toggle off does not leak one last report on next launch.
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> send(
    String error,
    StackTrace? stack, {
    String? context,
    required bool fatal,
    required List<String> breadcrumbs,
  }) async {
    // Breadcrumbs first: Crashlytics attaches the log lines already recorded
    // when the report lands, so ordering here is load-bearing.
    for (final crumb in breadcrumbs) {
      await _crashlytics.log(crumb);
    }
    await _crashlytics.recordError(
      // Already scrubbed by CrashReporter — see the contract on CrashSink.
      // Passing the cleaned STRING, not the original exception, is the point:
      // an exception object can hold recipe text in fields no scrubber reaches.
      error,
      stack,
      reason: context,
      fatal: fatal,
    );
  }
}
