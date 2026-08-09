// CrashLog: the local error ring-buffer behind the Settings footer door.
// Contract under test: never throws, caps at 50, survives corrupt files,
// inert stays off disk, export reads newest-first.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/crash_log.dart';

void main() {
  late Directory tmp;
  late File file;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('myrecibook_crash_log');
    file = File('${tmp.path}/crash_log.json');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('missing file loads empty', () async {
    final log = await CrashLog.load(file);
    expect(log.count, 0);
    expect(log.entries, isEmpty);
  });

  test('corrupt file loads empty, never throws', () async {
    await file.writeAsString('{not json');
    final log = await CrashLog.load(file);
    expect(log.count, 0);
    // and it recovers: a new record persists cleanly
    await log.record('boom', StackTrace.current);
    final reloaded = await CrashLog.load(file);
    expect(reloaded.count, 1);
  });

  test('record persists error, context and clipped stack', () async {
    final log = await CrashLog.load(file);
    await log.record('the sky fell', StackTrace.current, context: 'building X');
    final reloaded = await CrashLog.load(file);
    final e = reloaded.entries.single;
    expect(e['error'], 'the sky fell');
    expect(e['context'], 'building X');
    expect(e['at'], isNotNull);
    final stack = e['stack']! as String;
    expect(const LineSplitter().convert(stack).length, lessThanOrEqualTo(12));
  });

  test('ring caps at 50, keeps the newest', () async {
    final log = await CrashLog.load(file);
    for (var i = 0; i < 60; i++) {
      await log.record('error $i', null);
    }
    expect(log.count, 50);
    // newest first in entries; oldest surviving is error 10
    expect(log.entries.first['error'], 'error 59');
    expect(log.entries.last['error'], 'error 10');
    final reloaded = await CrashLog.load(file);
    expect(reloaded.count, 50);
  });

  test('burst of un-awaited records serializes without corruption', () async {
    final log = await CrashLog.load(file);
    // fire-and-forget, like real onError bursts
    final futures = [for (var i = 0; i < 20; i++) log.record('burst $i', null)];
    await Future.wait(futures);
    final reloaded = await CrashLog.load(file);
    expect(reloaded.count, 20);
  });

  test('api-key query params are redacted before storage', () async {
    final log = await CrashLog.load(file);
    await log.record(
        'ClientException: failed, uri=https://example.com/v1?key=AIzaSecret123',
        null,
        context: 'while calling key=AIzaSecret123');
    final e = (await CrashLog.load(file)).entries.single;
    expect('${e['error']}', isNot(contains('AIzaSecret123')));
    expect('${e['error']}', contains('key=…'));
    expect('${e['context']}', isNot(contains('AIzaSecret123')));
  });

  test('oversized error strings are clipped', () async {
    final log = await CrashLog.load(file);
    await log.record('x' * 2000, null);
    final stored = log.entries.single['error']! as String;
    expect(stored.length, lessThanOrEqualTo(501)); // 500 + ellipsis
  });

  test('clear empties memory and disk', () async {
    final log = await CrashLog.load(file);
    await log.record('gone soon', null);
    await log.clear();
    expect(log.count, 0);
    expect((await CrashLog.load(file)).count, 0);
  });

  test('export is newest-first flat text', () async {
    final log = await CrashLog.load(file);
    await log.record('first', null);
    await log.record('second', null);
    final text = log.export();
    expect(text.indexOf('second'), lessThan(text.indexOf('first')));
  });

  test('inert records in memory only and touches no disk', () async {
    final log = CrashLog.inert();
    await log.record('memory only', null);
    expect(log.count, 1);
    expect(await tmp.list().length, 0);
  });
}
