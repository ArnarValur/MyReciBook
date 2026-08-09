// The ONE tmp+rename discipline (review 2026-08-09: five hand-rolled copies
// had already drifted). Write `<path>.tmp` flushed, then rename over the
// target — a mid-write kill leaves the previous file intact, never a
// truncated one. Writes to the SAME path serialize process-wide, so
// overlapping saves can't interleave on the shared tmp (rapid check-offs,
// double-fired save taps). The deterministic `.tmp` suffix is load-bearing:
// res/xml backup rules enumerate it and delete paths sweep it — don't switch
// to unique names without updating both.

import 'dart:async';
import 'dart:io';

final Map<String, Future<void>> _tails = {};

Future<void> writeStringAtomic(File file, String contents) {
  final path = file.path;
  final job = (_tails[path] ?? Future.value()).then((_) async {
    await file.parent.create(recursive: true);
    final tmp = File('$path.tmp');
    await tmp.writeAsString(contents, flush: true);
    await tmp.rename(path);
  });
  // The chain swallows so one failed write can't poison the queue; the
  // returned future still carries the error to this caller.
  final settled = job.then((_) {}, onError: (_) {});
  _tails[path] = settled;
  settled.whenComplete(() {
    if (identical(_tails[path], settled)) _tails.remove(path);
  });
  return job;
}
