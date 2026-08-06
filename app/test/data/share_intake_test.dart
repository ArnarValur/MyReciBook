// ShareIntake against a mocked share channel: cold-start drain filters to
// files that still exist; warm pushes reply successfully (a throw would
// re-queue the paths — bridge contract) and dedupe against the drain.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/share_intake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fake-share-test');
  const codec = StandardMethodCodec();
  late Directory tmp;
  List<String> pending = [];

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_share_test');
    pending = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'takePendingShared') {
        final out = List<String>.from(pending);
        pending.clear();
        return out;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tmp.delete(recursive: true);
  });

  Future<File> cachedShare(String name) =>
      File('${tmp.path}/$name').writeAsBytes([1, 2, 3]);

  Future<ByteData?> pushWarm(List<String> paths) async {
    ByteData? reply;
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
            channel.name,
            codec.encodeMethodCall(MethodCall('onSharedImages', paths)),
            (data) => reply = data);
    return reply;
  }

  test('takePending drains queue and filters to files that still exist',
      () async {
    final alive = await cachedShare('a.jpg');
    pending = [alive.path, '${tmp.path}/evicted.jpg'];

    final intake = ShareIntake(channel: channel);
    final files = await intake.takePending();
    expect(files.map((f) => f.path), [alive.path]);

    // Queue was drained — a second call yields nothing.
    expect(await intake.takePending(), isEmpty);
  });

  test('warm push fires callback with existing files and replies success',
      () async {
    final alive = await cachedShare('b.jpg');
    final intake = ShareIntake(channel: channel);
    List<File>? got;
    intake.onShared = (files) => got = files;

    final reply = await pushWarm([alive.path, '${tmp.path}/gone.jpg']);
    expect(got!.map((f) => f.path), [alive.path]);
    // A success reply is what un-queues the paths on the bridge side.
    expect(reply, isNotNull);
    expect(codec.decodeEnvelope(reply!), isNull);
  });

  test('warm-then-drain delivers each path once (dedupe by path)', () async {
    final alive = await cachedShare('c.jpg');
    final other = await cachedShare('d.jpg');
    final intake = ShareIntake(channel: channel);
    final warm = <String>[];
    intake.onShared = (files) => warm.addAll([for (final f in files) f.path]);

    await pushWarm([alive.path]);
    pending = [alive.path, other.path]; // bridge re-lists an already-pushed path

    final drained = await intake.takePending();
    expect(warm, [alive.path]);
    expect(drained.map((f) => f.path), [other.path]);
  });

  test('callback throw never breaks the reply (paths would re-queue)',
      () async {
    final alive = await cachedShare('e.jpg');
    final intake = ShareIntake(channel: channel);
    intake.onShared = (_) => throw StateError('listener bug');

    final reply = await pushWarm([alive.path]);
    expect(reply, isNotNull);
    expect(codec.decodeEnvelope(reply!), isNull); // still a success envelope
  });
}
