// Share-sheet intake (architecture §3.1): the bridge has already copied
// shared bytes into app-private cache; this wraps the channel that hands the
// cached paths over. Warm shares arrive via 'onSharedImages'; cold-start
// shares are drained once with takePending(). The handler must reply
// successfully or the bridge re-queues the paths — so it never throws, and
// paths are deduped here in case both routes deliver the same share.

import 'dart:io';

import 'package:flutter/services.dart';

class ShareIntake {
  ShareIntake({
    this.channel = const MethodChannel('com.merkurialstudio.myrecibook/share'),
  }) {
    channel.setMethodCallHandler(_handle);
  }

  final MethodChannel channel;
  final Set<String> _delivered = {};

  /// Warm-path pushes while the engine is attached. Set at boot, before
  /// registering could race an incoming share.
  void Function(List<File> images)? onShared;

  /// Cold-start drain: cached share copies that still exist, deduped against
  /// anything already delivered warm.
  Future<List<File>> takePending() async {
    final paths = await channel.invokeMethod<List<dynamic>>('takePendingShared');
    return _fresh((paths ?? const []).cast<String>());
  }

  Future<Object?> _handle(MethodCall call) async {
    if (call.method != 'onSharedImages') return null;
    try {
      final files = await _fresh((call.arguments as List).cast<String>());
      if (files.isNotEmpty) onShared?.call(files);
    } catch (_) {} // a throw would re-queue the paths (bridge contract)
    return null;
  }

  Future<List<File>> _fresh(List<String> paths) async {
    final files = <File>[];
    for (final path in paths) {
      if (!_delivered.add(path)) continue;
      final f = File(path);
      if (await f.exists()) files.add(f);
    }
    return files;
  }
}
