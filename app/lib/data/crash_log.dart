// Local error ring-buffer — the closed test's only crash story, since
// telemetry is ruled out (D8). Uncaught errors land here, on the device,
// and leave it only when the tester deliberately copies them out (the
// long-press door on the Settings version footer).
//
// Never fatal by construction: recording an error must not be able to crash
// or throw, so every IO path here swallows — losing a log line is always
// better than looping through onError.

import 'dart:convert';
import 'dart:io';

import 'atomic_file.dart';

class CrashLog {
  CrashLog._(this._file, this._entries);

  /// Real log at [file]; corrupt/missing content starts empty, never throws.
  static Future<CrashLog> load(File file) async {
    var entries = <Map<String, Object?>>[];
    try {
      if (await file.exists()) {
        final raw = jsonDecode(await file.readAsString());
        if (raw is List) {
          entries = [
            for (final e in raw)
              if (e is Map) e.cast<String, Object?>(),
          ];
        }
      }
    } catch (_) {
      entries = []; // corrupt log: worst case we lose old entries
    }
    return CrashLog._(file, entries);
  }

  /// Test seam / absent wiring: records in memory only, never touches disk.
  CrashLog.inert()
      : _file = null,
        _entries = [];

  final File? _file;
  final List<Map<String, Object?>> _entries;

  /// Newest first. Bounded by [cap], so this is safe to render directly.
  List<Map<String, Object?>> get entries => List.unmodifiable(_entries.reversed);

  int get count => _entries.length;

  static const int cap = 50;
  static const int _errorChars = 500;
  static const int _stackLines = 12;

  /// Fire-and-forget safe: swallows all IO errors, trims to [cap].
  Future<void> record(Object error, StackTrace? stack, {String? context}) {
    try {
      final s = stack?.toString();
      _entries.add({
        // UTC: copied logs must correlate unambiguously across timezones.
        'at': DateTime.now().toUtc().toIso8601String(),
        'error': _clip('$error', _errorChars),
        if (context != null && context.isNotEmpty)
          'context': _clip(context, _errorChars),
        if (s != null && s.isNotEmpty)
          'stack': (const LineSplitter())
              .convert(s)
              .take(_stackLines)
              .join('\n'),
      });
      if (_entries.length > cap) {
        _entries.removeRange(0, _entries.length - cap);
      }
      return _save();
    } catch (_) {
      return Future.value(); // the logger itself must never throw
    }
  }

  Future<void> clear() {
    _entries.clear();
    return _save();
  }

  /// One flat text block for the clipboard (newest first).
  String export() => [
        for (final e in entries)
          [
            '— ${e['at']}',
            if (e['context'] != null) 'while: ${e['context']}',
            '${e['error']}',
            if (e['stack'] != null) '${e['stack']}',
          ].join('\n'),
      ].join('\n\n');

  // Coalesced: an error BURST is this log's whole reason to exist, so it must
  // not become the jank generator — one pending write at a time, encoding the
  // LIVE ring when its turn comes. Records landing mid-write schedule exactly
  // one follow-up; writeStringAtomic serializes the file access.
  Future<void>? _pending;

  Future<void> _save() {
    final file = _file;
    if (file == null) return Future.value();
    return _pending ??= Future(() async {
      _pending = null; // from here on, new records need a fresh write
      try {
        await writeStringAtomic(file, jsonEncode(_entries));
      } catch (_) {
        // best-effort: a lost write costs log lines, never stability
      }
    });
  }

  // Transport exceptions can embed a full request URI — and the Gemini key
  // rides the query string until the D2 proxy lands. Redact before storing:
  // the log is copy-pasteable by design, so it must never carry a secret.
  static final _keyParam = RegExp(r'key=[A-Za-z0-9_\-]+');

  static String _clip(String s, int max) {
    final scrubbed = s.replaceAll(_keyParam, 'key=…');
    return scrubbed.length <= max ? scrubbed : '${scrubbed.substring(0, max)}…';
  }
}
