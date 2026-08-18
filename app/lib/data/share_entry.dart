// UI-facing share seam: shares can arrive before the folder gate resolves,
// so batches buffer here until the list screen attaches — the shared intent
// is never dropped (arch §3.1). The cold-start drain rides the first attach.
// Links (share-links spike) ride the same seam: buffered one URL at a time.

import 'dart:io';

class ShareEntry {
  ShareEntry({this.takePending, this.takePendingLinks});

  /// Cold-start drain (ShareIntake.takePending); null in widget tests.
  final Future<List<File>> Function()? takePending;

  /// Cold-start drain for link shares (ShareIntake.takePendingLinks).
  final Future<List<String>> Function()? takePendingLinks;

  void Function(List<File> images)? _listener;
  void Function(String url)? _linkListener;
  final List<File> _held = [];
  final List<String> _heldLinks = [];

  /// Wire to ShareIntake.onShared; tests call it directly.
  void push(List<File> images) {
    if (images.isEmpty) return;
    if (_listener == null) {
      _held.addAll(images);
    } else {
      _listener!(images);
    }
  }

  /// Wire to ShareIntake.onSharedLink; tests call it directly.
  void pushLink(String url) {
    if (url.isEmpty) return;
    if (_linkListener == null) {
      _heldLinks.add(url);
    } else {
      _linkListener!(url);
    }
  }

  Future<void> attach(
    void Function(List<File> images) listener, {
    void Function(String url)? onLink,
  }) async {
    _listener = listener;
    _linkListener = onLink;
    if (_held.isNotEmpty) {
      final held = [..._held];
      _held.clear();
      push(held);
    }
    if (_heldLinks.isNotEmpty) {
      final held = [..._heldLinks];
      _heldLinks.clear();
      held.forEach(pushLink);
    }
    if (takePending != null) {
      try {
        push(await takePending!());
      } catch (_) {} // a failed drain must never break boot
    }
    if (takePendingLinks != null) {
      try {
        (await takePendingLinks!()).forEach(pushLink);
      } catch (_) {} // same rule as the image drain
    }
  }

  void detach() {
    _listener = null;
    _linkListener = null;
  }
}
