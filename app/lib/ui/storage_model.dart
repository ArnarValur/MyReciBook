// Connector state (D3 pattern: pure op → notify → best-effort persist) over
// the stage-1/2 layers: OAuthFlow owns the browser dance, TokenStore the
// persisted grants, SyncEngine the mirror passes. Exactly one connector is
// active at a time — the design is "pick where your files live" (3h). The
// honesty rule is hard: the model never reports a state it can't prove —
// 'synced' only after a pass landed, a file count only after a real remote
// list, 'reconnect' the moment auth is known dead.
//
// Config: prod main reads DRIVE_CLIENT_ID / DROPBOX_APP_KEY via
// String.fromEnvironment with 'placeholder-*' defaults. app/dev.env (rule 6:
// gitignored, read by device builds via --dart-define-from-file) gains
// DRIVE_CLIENT_ID=... and DROPBOX_APP_KEY=... when Arnar's credentials land;
// until then placeholders keep connect() in the honest notConfigured state.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/app_settings.dart';
import '../data/oauth.dart';
import '../data/remote_store.dart';
import '../data/saf_store.dart' show GrantLostException;
import '../data/sync_engine.dart';
import '../data/token_store.dart';

/// Builds the engine over the CURRENT sync source + app-private manifest.
/// Reads the live folder config at call time (the engine is rebuilt per
/// operation so a re-picked folder is never mirrored through a stale source).
/// Null = nothing to mirror yet (no folder picked).
typedef EngineFactory = SyncEngine? Function(
    RemoteStore remote, void Function(SyncStatus) onStatus);

/// Test seam: replaces the real Drive/Dropbox stores. [client] is null when
/// the model has no flow/token wiring (inert default instance).
typedef RemoteFactory = RemoteStore Function(
    String provider, AuthedClient? client);

class StorageModel extends ChangeNotifier {
  StorageModel({
    this._settings,
    this._tokenStore,
    this._flow,
    this._client,
    this.driveClientId = 'placeholder-drive',
    this.dropboxAppKey = 'placeholder-dropbox',
    this._engineFactory,
    this._remoteFactory,
    this.syncDebounce = const Duration(seconds: 3),
  }) {
    final active = _settings?.activeConnector;
    if (active != null) {
      _active = active;
      if (_tokenStore?.tokens(active) != null) {
        _remote = _buildRemote(active);
      } else {
        // Persisted connector but no tokens (cleared/corrupt store): honest
        // reconnect state — never a silent "connected".
        _status = const SyncStatus(SyncState.authRevoked,
            error: 'stored tokens missing');
      }
    }
  }

  static const drive = 'drive';
  static const dropbox = 'dropbox';

  final AppSettings? _settings;
  final TokenStore? _tokenStore;
  final OAuthFlow? _flow;
  final http.Client? _client;
  final String driveClientId;
  final String dropboxAppKey;
  final EngineFactory? _engineFactory;
  final RemoteFactory? _remoteFactory;
  final Duration syncDebounce;

  /// Set by main's appBuilder glue — a lost SAF grant during a sync pass
  /// joins the existing BootGate re-pick flow (§7), never a crash.
  VoidCallback? onGrantLost;

  String? _active;
  RemoteStore? _remote;
  SyncStatus _status = const SyncStatus(SyncState.idle);
  int? _remoteFileCount;
  String? _connecting;
  String? _notConfigured;
  String? _errorProvider;
  String? _errorMessage;
  Timer? _debounce;
  bool _disposed = false;
  Future<void> _tail = Future.value(); // serializes sync/restore ops

  /// Active connector key ('drive' / 'dropbox'), null = this phone only.
  String? get active => _active;

  /// Relayed engine status — the value snapshot the UI renders truthfully.
  SyncStatus get status => _status;

  /// Files in the remote mirror; null until a real remote list happened.
  int? get remoteFileCount => _remoteFileCount;

  /// Provider with a connect flow in flight, null otherwise.
  String? get connecting => _connecting;

  /// Provider whose connect hit placeholder credentials — the UI's honest
  /// "awaiting keys in this build" state.
  String? get notConfigured => _notConfigured;

  /// Last transient connect failure, keyed to its provider card.
  String? connectErrorFor(String provider) =>
      provider == _errorProvider ? _errorMessage : null;

  bool configured(String provider) =>
      _flow != null && !_providerConfig(provider).isPlaceholder;

  String displayName(String provider) =>
      provider == dropbox ? 'Dropbox' : 'Google Drive';

  String shortName(String provider) => provider == dropbox ? 'Dropbox' : 'Drive';

  /// 'synced X ago' clock: just now / N min / N hr / N days.
  static String relative(DateTime t, {DateTime? now}) {
    final d = (now ?? DateTime.now()).difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} hr ago';
    return '${d.inDays} day${d.inDays == 1 ? '' : 's'} ago';
  }

  /// Drawer Storage row trailing — only states that are true (turn-5 5c).
  String drawerSummary({String? folderName}) {
    final active = _active;
    if (active == null) {
      return folderName == null ? 'This phone' : 'This phone · $folderName';
    }
    final name = shortName(active);
    return switch (_status.state) {
      SyncState.syncing => '$name · syncing…',
      SyncState.synced when _status.syncedAt != null =>
        '$name · synced ${relative(_status.syncedAt!)}',
      SyncState.offline => '$name · offline',
      SyncState.authRevoked => '$name · reconnect',
      _ => name,
    };
  }

  /// Provider-card status line (5b language, truthful parts only); null when
  /// [provider] isn't the active connector. Drive files live in an
  /// app-visible 'MyReciBook' folder; Dropbox in its app folder.
  String? statusLine(String provider) {
    if (provider != _active) return null;
    final count = _remoteFileCount;
    return [
      provider == dropbox ? 'app folder' : 'MyReciBook',
      if (count != null) '$count file${count == 1 ? '' : 's'}',
      switch (_status.state) {
        SyncState.syncing => 'syncing…',
        SyncState.synced when _status.syncedAt != null =>
          'synced ${relative(_status.syncedAt!)}',
        SyncState.offline => 'offline — will retry',
        SyncState.authRevoked => 'reconnect needed',
        _ => 'connected',
      },
    ].join(' · ');
  }

  /// OAuth dance → tokens stored → active persisted → initial mirror pass.
  /// Never throws: every failure becomes a surfaced state (notConfigured /
  /// quiet cancel / connectError). Connecting provider B while A is active
  /// disconnects A first — one connector at a time.
  Future<void> connect(String provider) async {
    _notConfigured = null;
    _errorProvider = null;
    _errorMessage = null;
    final flow = _flow;
    final tokenStore = _tokenStore;
    if (flow == null || tokenStore == null) {
      _notConfigured = provider; // inert build — same honest state
      _notify();
      return;
    }
    _connecting = provider;
    _notify();
    final TokenSet tokens;
    try {
      tokens = await flow.begin(_providerConfig(provider));
    } on NotConfiguredException {
      _connecting = null;
      _notConfigured = provider;
      _notify();
      return;
    } on AuthCancelledException {
      _connecting = null; // superseded by a newer attempt — stay quiet
      _notify();
      return;
    } on OAuthException catch (e) {
      _connecting = null;
      _errorProvider = provider;
      _errorMessage = e.message;
      _notify();
      return;
    }
    final old = _active;
    _active = provider;
    _connecting = null;
    _remoteFileCount = null;
    _status = const SyncStatus(SyncState.idle);
    _notify();
    // Tokens must land before the sync (AuthedClient reads the store).
    await _guard(() => tokenStore.setTokens(provider, tokens));
    if (old != null && old != provider) {
      await _guard(() => tokenStore.setTokens(old, null));
    }
    await _guard(() => _settings?.setActiveConnector(provider));
    _remote = _buildRemote(provider);
    await _sync(); // initial pass — relayed statuses keep the UI live
  }

  /// Clears tokens + active connector and stops syncing. Remote files stay
  /// where they are — they're the user's copy, never deleted on disconnect.
  Future<void> disconnect() async {
    final old = _active;
    if (old == null) return;
    _debounce?.cancel();
    _debounce = null;
    _active = null;
    _remote = null;
    _remoteFileCount = null;
    _status = const SyncStatus(SyncState.idle);
    _notify();
    await _guard(() => _tokenStore?.setTokens(old, null));
    await _guard(() => _settings?.setActiveConnector(null));
  }

  /// Debounced (~3 s) fire-and-forget sync — rapid batch saves coalesce into
  /// one pass. No-op without an active, token-backed connector.
  void syncSoon() {
    if (_active == null || _remote == null) return;
    _debounce?.cancel();
    _debounce = Timer(syncDebounce, () {
      _debounce = null;
      unawaited(_sync());
    });
  }

  /// Explicit "book reappears" (5a): additive engine.restoreDown. Typed
  /// failures (SyncIoException / AuthRevokedException) rethrow so the screen
  /// can speak honestly; GrantLost routes to the re-pick flow and rethrows.
  /// Returns the number of files copied back for the confirmation UI.
  Future<int> restore() => _serial(() async {
        final remote = _remote;
        if (remote == null) throw SyncIoException('no connector active');
        final engine = _engineFactory?.call(remote, _onStatus);
        if (engine == null) throw SyncIoException('no connector active');
        try {
          final n = await engine.restoreDown();
          await _refreshCount(remote);
          return n;
        } on GrantLostException {
          onGrantLost?.call();
          rethrow;
        }
      });

  Future<void> _sync() => _serial(() async {
        final remote = _remote;
        if (remote == null) return;
        final engine = _engineFactory?.call(remote, _onStatus);
        if (engine == null) return;
        try {
          await engine.syncUp(); // never throws for transport/auth (§7)
        } on GrantLostException {
          onGrantLost?.call();
          return;
        }
        if (engine.status.state == SyncState.synced) {
          await _refreshCount(remote);
        }
      });

  Future<void> _refreshCount(RemoteStore remote) async {
    try {
      _remoteFileCount = (await remote.list()).length;
      _notify();
    } catch (_) {} // the count is a nicety — never fail a good pass over it
  }

  RemoteStore? _buildRemote(String provider) {
    final flow = _flow;
    final tokenStore = _tokenStore;
    AuthedClient? authed;
    if (flow != null && tokenStore != null) {
      authed = AuthedClient(
        provider: _providerConfig(provider),
        flow: flow,
        tokenStore: tokenStore,
        tokenKey: provider,
        client: _client,
      );
    }
    final factory = _remoteFactory;
    if (factory != null) return factory(provider, authed);
    if (authed == null) return null;
    return provider == dropbox ? DropboxRemote(authed) : DriveRemote(authed);
  }

  OAuthProvider _providerConfig(String provider) => provider == dropbox
      ? OAuthProvider.dropbox(dropboxAppKey)
      : OAuthProvider.googleDrive(driveClientId);

  void _onStatus(SyncStatus s) {
    _status = s;
    _notify();
  }

  Future<T> _serial<T>(Future<T> Function() job) {
    // One engine op at a time: concurrent restore + debounced sync would race
    // two engines over the same manifest file.
    final run = _tail.then((_) => job());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<void> _guard(Future<void>? Function() op) async {
    try {
      await op();
    } catch (_) {} // persistence best-effort — in-memory state already live
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
