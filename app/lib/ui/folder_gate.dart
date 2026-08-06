// Boot flow (arch §4, §7): the store exists only after the user picks a SAF
// folder, so BootGate owns that resolution — gate screen until a grant holds,
// then the real app subtree via [appBuilder]. Grant lost mid-session re-enters
// the gate with re-pick copy; the settings slot is reused, never a crash.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings.dart';
import '../data/migration.dart';
import '../data/recipe_store.dart';
import '../data/saf_store.dart';
import 'theme.dart';

enum _Boot { checking, gate, migrating, ready }

class BootGate extends StatefulWidget {
  const BootGate({
    super.key,
    required this.settings,
    required this.localStore,
    required this.imageCache,
    required this.appBuilder,
    this.safChannel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  final AppSettings settings;

  /// Pre-gate app-private store — the one-shot migration source.
  final LocalFolderStore localStore;
  final Directory imageCache;

  /// Builds the real app once a store exists; the callback re-enters the gate.
  final Widget Function(SafFolderStore store, VoidCallback onGrantLost)
      appBuilder;
  final MethodChannel safChannel;

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  _Boot _phase = _Boot.checking;
  bool _lost = false;
  bool _picking = false;
  SafFolderStore? _store;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final uri = widget.settings.treeUri;
    if (uri != null) {
      var ok = false;
      try {
        ok = await widget.safChannel
                .invokeMethod<bool>('hasGrant', {'uri': uri}) ??
            false;
      } catch (_) {} // hasGrant never throws by contract; belt and braces
      if (ok) {
        await _enter(uri);
        return;
      }
      _lost = true;
    }
    if (mounted) setState(() => _phase = _Boot.gate);
  }

  Future<void> _pick() async {
    if (_picking) return;
    _picking = true;
    try {
      final uri = await widget.safChannel.invokeMethod<String>('pickFolder');
      if (uri == null || !mounted) return; // user cancelled
      final old = widget.settings.treeUri;
      if (old != null && old != uri) {
        try {
          await widget.safChannel
              .invokeMethod<void>('releaseGrant', {'uri': old});
        } catch (_) {}
      }
      await widget.settings.setTreeUri(uri);
      await _enter(uri);
    } on PlatformException {
      // Picker failed to launch (SAF_IO): stay on the gate.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Couldn't open the folder picker — try again")));
      }
    } finally {
      _picking = false;
    }
  }

  Future<void> _enter(String uri) async {
    final store = SafFolderStore(
      treeUri: uri,
      imageCache: widget.imageCache,
      channel: widget.safChannel,
    );
    if (!widget.settings.migrationDone) {
      if (mounted) setState(() => _phase = _Boot.migrating);
      try {
        await migrateLocalToSaf(widget.localStore, store,
            settings: widget.settings);
      } on GrantLostException {
        // Flag stays unset — re-pick, then the migration runs again.
        if (mounted) {
          setState(() {
            _lost = true;
            _phase = _Boot.gate;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _store = store;
        _phase = _Boot.ready;
      });
    }
  }

  void _onGrantLost() {
    if (!mounted || _phase != _Boot.ready) return;
    setState(() {
      _lost = true;
      _store = null;
      _phase = _Boot.gate;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Boot.ready) return widget.appBuilder(_store!, _onGrantLost);
    return MaterialApp(
      title: 'MyReciBook',
      theme: rbLightTheme(),
      darkTheme: rbDarkTheme(),
      home: switch (_phase) {
        _Boot.gate => FolderGate(lost: _lost, onPick: _pick),
        _ => _Busy(
            label: _phase == _Boot.migrating ? 'Moving your recipes in…' : null),
      },
    );
  }
}

class _Busy extends StatelessWidget {
  const _Busy({this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (label != null) ...[
              const SizedBox(height: 16),
              Text(label!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: context.scheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}

/// First-run / re-pick gate — a real screen, minimal on purpose.
class FolderGate extends StatelessWidget {
  const FolderGate({super.key, required this.onPick, this.lost = false});

  final VoidCallback onPick;
  final bool lost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          lost
                              ? Icons.folder_off_rounded
                              : Icons.folder_rounded,
                          size: 32,
                          color: scheme.primary),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      lost
                          ? 'Pick your folder again'
                          : 'Where should your recipes live?',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontSize: 22, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      lost
                          ? 'Your recipes folder moved or access was lost — '
                              'pick it again. Your files are untouched.'
                          : 'Pick a folder on this phone. Every recipe is '
                              'saved there as a plain file — your folder, your '
                              'files. The app reads and writes only in there.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.55),
                    ),
                  ],
                ),
              ),
              // Gradient-FAB treatment on the one primary action.
              Container(
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [scheme.primaryContainer, scheme.primary],
                  ),
                  boxShadow: context.rb.glowFab,
                ),
                child: FilledButton.icon(
                  key: const Key('choose-folder-button'),
                  onPressed: onPick,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: scheme.onPrimary,
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 20),
                  label: const Text('Choose folder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
