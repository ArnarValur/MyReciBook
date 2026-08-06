// One-way mirror (arch §4: the folder IS the source of truth; the remote is
// backup + restore, full 2-way sync is out of v1 scope). syncUp pushes
// new/changed/vanished; restoreDown is the explicit "book reappears" path —
// additive only, an existing name is never overwritten. The manifest
// (app-private JSON, tmp+rename, corrupt → start clean) remembers what last
// landed remotely, so a crash mid-pass resumes instead of re-uploading the
// world. Content is re-read and hashed every pass on purpose: the SAF channel
// exposes no size/mtime, and correctness beats cleverness at v1 scale.
// No Flutter imports here — the engine stays pure Dart.

import 'dart:convert';
import 'dart:io';

import 'remote_store.dart';
import 'sha256.dart';
import 'sync_source.dart';

enum SyncState { idle, syncing, synced, authRevoked, offline }

/// Value snapshot for the UI: state + when the last pass landed + the
/// offline cause. Stage 3 adapts it to a ChangeNotifier at the edge.
class SyncStatus {
  final SyncState state;
  final DateTime? syncedAt;
  final String? error;

  const SyncStatus(this.state, {this.syncedAt, this.error});

  @override
  String toString() => 'SyncStatus($state${error == null ? '' : ': $error'})';
}

class SyncEngine {
  SyncEngine({
    required this.source,
    required this.remote,
    required this.manifestFile,
    this.onStatus,
  });

  final SyncSource source;
  final RemoteStore remote;

  /// App-private manifest: name → {size, sha256} of the last upload.
  final File manifestFile;

  final void Function(SyncStatus)? onStatus;

  SyncStatus _status = const SyncStatus(SyncState.idle);
  SyncStatus get status => _status;

  Map<String, Map<String, Object?>>? _manifest;
  Future<void>? _inflightUp;
  Future<void> _tail = Future.value(); // serializes syncUp/restoreDown

  // Deletions propagate only for names this app owns — '<uuid>.json' or
  // images/* — so foreign remote files are never touched.
  static final _uuidJson = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\.json$');

  static bool _ownedName(String name) =>
      _uuidJson.hasMatch(name) ||
      (name.startsWith('images/') && SyncSource.safeName(name));

  void _emit(SyncStatus s) {
    _status = s;
    onStatus?.call(s);
  }

  Future<T> _enqueue<T>(Future<T> Function() job) {
    final run = _tail.then((_) => job());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  /// Pushes the folder to the remote. Transport/auth failures never throw —
  /// they become [status] offline/authRevoked (§7 stances) and the next pass
  /// resumes from the manifest. GrantLostException propagates: the app's
  /// existing re-pick flow owns it. Concurrent calls coalesce into one pass.
  Future<void> syncUp() {
    final inflight = _inflightUp;
    if (inflight != null) return inflight;
    late final Future<void> run;
    run = _enqueue(_syncUp).whenComplete(() {
      if (identical(_inflightUp, run)) _inflightUp = null;
    });
    return _inflightUp = run;
  }

  Future<void> _syncUp() async {
    _emit(const SyncStatus(SyncState.syncing));
    try {
      final manifest = await _loadManifest();
      final local = await source.list();

      final names = local.keys.toList()..sort(); // deterministic order
      for (final name in names) {
        if (!SyncSource.safeName(name)) continue; // outside the layout: skip
        final bytes = await source.read(name);
        final hash = _hex(sha256(bytes));
        if (manifest[name]?['sha256'] == hash) continue; // already landed
        await remote.upload(name, bytes);
        manifest[name] = {'size': bytes.length, 'sha256': hash};
        await _saveManifest(); // per file: crash mid-pass resumes, not restarts
      }

      final vanished =
          manifest.keys.where((n) => !local.containsKey(n)).toList();
      for (final name in vanished) {
        if (_ownedName(name)) await remote.delete(name);
        manifest.remove(name);
        await _saveManifest();
      }

      _emit(SyncStatus(SyncState.synced, syncedAt: DateTime.now()));
    } on SyncIoException catch (e) {
      _emit(SyncStatus(SyncState.offline, error: e.message));
    } on AuthRevokedException catch (e) {
      _emit(SyncStatus(SyncState.authRevoked, error: e.message));
    } catch (_) {
      _emit(const SyncStatus(SyncState.idle));
      rethrow; // GrantLost and friends — the caller's flow owns them
    }
  }

  /// Pulls every remote file the folder doesn't already have (additive —
  /// restore never overwrites; design 5a "the book reappears"). Explicit
  /// action, so typed failures DO throw here. Returns the count restored.
  Future<int> restoreDown() => _enqueue(_restoreDown);

  Future<int> _restoreDown() async {
    _emit(const SyncStatus(SyncState.syncing));
    try {
      final manifest = await _loadManifest();
      final remoteFiles = await remote.list();
      final local = await source.list();
      var restored = 0;
      final names = remoteFiles.keys.toList()..sort();
      for (final name in names) {
        if (!SyncSource.safeName(name)) continue; // hostile remote name (§7)
        if (local.containsKey(name)) continue; // additive only
        final bytes = await remote.download(name);
        await source.write(name, bytes);
        // Record it as landed so the next syncUp doesn't push it right back.
        manifest[name] = {'size': bytes.length, 'sha256': _hex(sha256(bytes))};
        await _saveManifest();
        restored++;
      }
      _emit(SyncStatus(SyncState.synced, syncedAt: DateTime.now()));
      return restored;
    } on SyncIoException catch (e) {
      _emit(SyncStatus(SyncState.offline, error: e.message));
      rethrow;
    } on AuthRevokedException catch (e) {
      _emit(SyncStatus(SyncState.authRevoked, error: e.message));
      rethrow;
    } catch (_) {
      _emit(const SyncStatus(SyncState.idle));
      rethrow;
    }
  }

  Future<Map<String, Map<String, Object?>>> _loadManifest() async {
    final loaded = _manifest;
    if (loaded != null) return loaded;
    var files = <String, Map<String, Object?>>{};
    try {
      if (await manifestFile.exists()) {
        final raw = (jsonDecode(await manifestFile.readAsString())
            as Map<String, dynamic>)['files'];
        if (raw is Map) {
          files = {
            for (final e in raw.entries)
              if (e.value is Map)
                e.key as String: (e.value as Map).cast<String, Object?>(),
          };
        }
      }
    } catch (_) {
      files = {}; // corrupt manifest: worst case a re-upload, never a crash
    }
    return _manifest = files;
  }

  Future<void> _saveManifest() async {
    await manifestFile.parent.create(recursive: true);
    final tmp = File('${manifestFile.path}.tmp');
    await tmp.writeAsString(jsonEncode({'files': _manifest ?? const {}}),
        flush: true);
    await tmp.rename(manifestFile.path);
  }
}

String _hex(List<int> bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
