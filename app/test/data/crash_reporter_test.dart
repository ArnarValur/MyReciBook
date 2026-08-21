// The reporter's two jobs: never lose an error locally, and never ship user
// content when it uploads (audit H1, 2026-08-21). The scrubbing tests are the
// load-bearing ones — a miss there puts somebody's recipe in a dashboard.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/crash_log.dart';
import 'package:myrecibook/data/crash_reporter.dart';

class _FakeSink implements CrashSink {
  final List<String> sent = [];
  final List<List<String>> crumbs = [];
  final List<bool> enabledCalls = [];
  bool fail = false;

  @override
  Future<void> setEnabled(bool enabled) async => enabledCalls.add(enabled);

  @override
  Future<void> send(
    String error,
    StackTrace? stack, {
    String? context,
    required bool fatal,
    required List<String> breadcrumbs,
  }) async {
    if (fail) throw StateError('upload failed');
    sent.add(error);
    crumbs.add(breadcrumbs);
  }
}

void main() {
  group('scrubForUpload', () {
    test('strips the Gemini key in every shape it reaches an error', () {
      expect(scrubForUpload('GET https://x/v1?key=AIzaSyABC-123_def'),
          'GET https://x/v1?key=…');
    });

    test('strips bearer tokens and stored OAuth tokens', () {
      expect(scrubForUpload('Authorization: Bearer ya29.a0Af-lonG_tok.en'),
          'Authorization: Bearer …');
      expect(
          scrubForUpload('{"refresh_token":"1//0gLonGsecret","x":1}'),
          '{"refresh_token":"…","x":1}');
    });

    // The one that matters most: a recipe file is named after the recipe.
    test('drops the recipe title out of a file path but keeps the shape', () {
      expect(
        scrubForUpload(
            "FileSystemException: /storage/emulated/0/Recipes/Grandmas-Lasagne.json"),
        'FileSystemException: /…/….json',
      );
      expect(scrubForUpload('failed to decode /data/cache/cover-99.jpg'),
          'failed to decode /…/….jpg');
    });

    test('drops SAF content uris — they carry the folder layout', () {
      expect(
          scrubForUpload(
              'SecurityException on content://com.android.providers/tree/primary%3ARecipes'),
          'SecurityException on content://…');
    });

    test('leaves an ordinary error untouched', () {
      const plain = 'RangeError: Invalid value: Not in inclusive range 0..5: 9';
      expect(scrubForUpload(plain), plain);
    });
  });

  group('CrashReporter', () {
    test('records locally even when reporting is off', () {
      final log = CrashLog.inert();
      final sink = _FakeSink();
      CrashReporter(log: log, sink: sink, enabled: false)
          .record(StateError('boom'), StackTrace.current);
      expect(log.count, 1, reason: 'the local log never depends on consent');
      expect(sink.sent, isEmpty, reason: 'nothing may leave without opt-in');
    });

    test('uploads a scrubbed string once enabled', () async {
      final log = CrashLog.inert();
      final sink = _FakeSink();
      final reporter = CrashReporter(log: log, sink: sink, enabled: true);
      reporter.record(
          StateError('cannot read /storage/Recipes/Secret-Cake.json'), null);
      await Future<void>.delayed(Duration.zero); // fire-and-forget send
      expect(sink.sent.single, contains('/…/….json'));
      expect(sink.sent.single, isNot(contains('Secret-Cake')));
    });

    test('breadcrumbs ride along, oldest first', () async {
      final log = CrashLog.inert();
      await log.record('first', null);
      await log.record('second', null);
      final sink = _FakeSink();
      CrashReporter(log: log, sink: sink, enabled: true)
          .record(StateError('third'), null);
      await Future<void>.delayed(Duration.zero);
      final crumbs = sink.crumbs.single;
      expect(crumbs.first, contains('first'));
      expect(crumbs.last, contains('third'));
    });

    test('an upload failure never escapes the hook', () async {
      final log = CrashLog.inert();
      final sink = _FakeSink()..fail = true;
      final reporter = CrashReporter(log: log, sink: sink, enabled: true);
      expect(() => reporter.record(StateError('boom'), null), returnsNormally);
      await Future<void>.delayed(Duration.zero);
      expect(log.count, 1);
    });

    test('setEnabled mirrors into the sink so uploads stop at once', () async {
      final sink = _FakeSink();
      final reporter =
          CrashReporter(log: CrashLog.inert(), sink: sink, enabled: true);
      await reporter.setEnabled(false);
      expect(sink.enabledCalls, [false]);
      reporter.record(StateError('boom'), null);
      await Future<void>.delayed(Duration.zero);
      expect(sink.sent, isEmpty);
    });

    test('no sink configured is a quiet no-op, not a crash', () {
      final log = CrashLog.inert();
      final reporter = CrashReporter(log: log, enabled: true);
      expect(reporter.hasSink, isFalse);
      expect(() => reporter.record(StateError('boom'), null), returnsNormally);
      expect(log.count, 1);
    });
  });
}
