// UI-facing share seam: shares can arrive before the folder gate resolves,
// so batches buffer here until the list screen attaches — the shared intent
// is never dropped (arch §3.1). The cold-start drain rides the first attach.

import 'dart:io';

class ShareEntry {
  ShareEntry({this.takePending});

  /// Cold-start drain (ShareIntake.takePending); null in widget tests.
  final Future<List<File>> Function()? takePending;

  void Function(List<File> images)? _listener;
  final List<File> _held = [];

  /// Wire to ShareIntake.onShared; tests call it directly.
  void push(List<File> images) {
    if (images.isEmpty) return;
    if (_listener == null) {
      _held.addAll(images);
    } else {
      _listener!(images);
    }
  }

  Future<void> attach(void Function(List<File> images) listener) async {
    _listener = listener;
    if (_held.isNotEmpty) {
      final held = [..._held];
      _held.clear();
      push(held);
    }
    if (takePending == null) return;
    try {
      push(await takePending!());
    } catch (_) {} // a failed drain must never break boot
  }

  void detach() => _listener = null;
}
