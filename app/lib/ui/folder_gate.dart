// Boot flow (arch §4, §7): the store exists only after the user picks a SAF
// folder, so BootGate owns that resolution — gate screen until a grant holds,
// then the real app subtree via [appBuilder]. Grant lost mid-session re-enters
// the gate with re-pick copy; the settings slot is reused, never a crash.
//
// Since 2026-08-27 the gate is one stop in a longer FIRST-RUN flow:
//
//   never picked a folder → welcome → setup (folder + units + theme) → slides
//   folder + grant, onboarding behind → slides → app
//   folder but grant gone  → the re-pick gate, exactly as before → app
//
// The three paths matter. A returning user whose grant lapsed must NOT be
// walked through welcome and setup again — they have an app, they lost a
// permission. And a first-run user must never meet the bare system picker as
// screen one, which is what shipped until now.

import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/app_settings.dart';
import '../data/migration.dart';
import '../data/product_store.dart';
import '../data/recipe_store.dart';
import '../data/saf_pantry_store.dart';
import '../data/saf_store.dart';
import '../domain/app_language.dart';
import '../domain/units.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_shell.dart' show folderDisplayName;
import 'onboarding/first_run_setup_screen.dart';
import 'onboarding/onboarding.dart';
import 'onboarding/slides_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'theme.dart';

enum _Boot { checking, welcome, setup, gate, migrating, slides, ready }

class BootGate extends StatefulWidget {
  const BootGate({
    super.key,
    required this.settings,
    required this.localStore,
    required this.imageCache,
    required this.appBuilder,
    this.localPantry,
    this.pantryImageCache,
    this.themeMode,
    this.locale,
    this.appNavigatorKey,
    this.units,
    this.onUnits,
    this.onThemeMode,
    this.safChannel = const MethodChannel('com.merkurialstudio.myrecibook/saf'),
  });

  /// Live unit system, for the setup screen's segmented control. Null (tests)
  /// makes the control show the as-written default and do nothing.
  final ValueListenable<UnitSystem>? units;

  /// Setup-screen writes. They go to the app-lifetime UnitsModel/ThemeModel
  /// rather than straight to settings, so the choice reaches every listener
  /// immediately instead of waiting for a restart. Null (tests) = inert.
  final ValueChanged<UnitSystem>? onUnits;
  final ValueChanged<ThemeMode>? onThemeMode;

  /// The READY-phase app's navigator key (main passes the same key into
  /// buildApp). The change-folder confirm and picker-failure snackbar need a
  /// navigator while the app is up — a deliberate change no longer passes
  /// through the gate. Never used as the gate MaterialApp's own key: sharing
  /// one GlobalKey across the two MaterialApps makes the swap reparent the
  /// Navigator element and the handoff wedges. Null (tests): ready-phase
  /// confirm degrades to switch-without-asking.
  final GlobalKey<NavigatorState>? appNavigatorKey;

  final AppSettings settings;

  /// The user's saved theme preference. The gate builds its OWN MaterialApp
  /// (it lives before the real app's), and without this it defaulted to
  /// ThemeMode.system — dark gate over a light in-app choice (Arnar's S21
  /// pass, 2026-08-06). Listenable so a settings change reaches a later
  /// re-entry (change-folder) without a restart; null keeps system (tests).
  final ValueListenable<ThemeMode>? themeMode;

  /// The user's saved interface language, for the same reason as [themeMode]:
  /// the gate's MaterialApp is built before the provider tree exists, so
  /// without this it would resolve the phone's language and ignore an in-app
  /// choice. Null (tests, and follow-the-phone) lets the platform resolve.
  final ValueListenable<Locale?>? locale;

  /// Pre-gate app-private store — the one-shot migration source.
  final LocalFolderStore localStore;
  final Directory imageCache;

  /// Pre-pantry app-private products (docs/pantry) — the pantry migration
  /// source, drained into `<tree>/pantry/` on entry. Null (tests): no pantry
  /// store is built and [appBuilder] receives null.
  final LocalPantryStore? localPantry;

  /// App-private hydration dir for SAF pantry photos (the recipes'
  /// imageCache twin). Required for the pantry store — null skips it.
  final Directory? pantryImageCache;

  /// Builds the real app once a store exists. [pantry] is the SAF-backed
  /// product store rooted in the same tree (null when [localPantry] /
  /// [pantryImageCache] were not given — the widget-test seam). The first
  /// callback re-enters the gate on a lost grant; the second is the
  /// deliberate change-folder door (Storage screen) — straight to the
  /// system picker, no gate screen.
  final Widget Function(SafFolderStore store, ProductStore? pantry,
      VoidCallback onGrantLost, VoidCallback onChangeFolder) appBuilder;
  final MethodChannel safChannel;

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  final _nav = GlobalKey<NavigatorState>();

  /// Dialog/snackbar host for the current phase: the running app's navigator
  /// when ready (deliberate change-folder skips the gate), the gate's own
  /// otherwise.
  BuildContext? get _dialogContext => _phase == _Boot.ready
      ? widget.appNavigatorKey?.currentContext
      : _nav.currentContext;
  _Boot _phase = _Boot.checking;
  bool _lost = false;
  bool _picking = false;

  /// Deliberate change-folder in flight — [_store] is kept so cancelling
  /// (picker back-out, "Keep current folder", dialog Cancel) returns to the
  /// running app instead of stranding on the gate.
  bool _changing = false;
  SafFolderStore? _store;
  SafPantryStore? _pantry;

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
      // Existing install whose permission lapsed. Straight to the re-pick
      // gate — this user has an app and a folder, they lost a grant. Walking
      // them back through welcome and setup would be theatre.
      _lost = true;
      if (mounted) setState(() => _phase = _Boot.gate);
      return;
    }
    // No folder has ever been picked on this device: first run.
    if (mounted) setState(() => _phase = _Boot.welcome);
  }

  /// True while this install has not finished the current onboarding revision.
  /// Bumping [kOnboardingVersion] makes it true again for everyone, which is
  /// the "here is what shipped" replay.
  bool get _onboardingPending =>
      widget.settings.onboardingSeen < kOnboardingVersion;

  /// Skip, the corner X and Done all land here — one exit, marked once.
  /// The write is best-effort: losing it costs a repeated slide, not data.
  Future<void> _finishOnboarding() async {
    if (mounted) setState(() => _phase = _Boot.ready);
    try {
      await widget.settings.setOnboardingSeen(kOnboardingVersion);
    } catch (_) {}
  }

  Future<void> _pick() async {
    if (_picking) return;
    _picking = true;
    try {
      final uri = await widget.safChannel.invokeMethod<String>('pickFolder');
      if (uri == null || !mounted) {
        _resumeCurrent(); // cancelled a deliberate change: back to the app
        return;
      }
      final old = widget.settings.treeUri;
      if (_changing && old != null && uri != old && !await _confirmSwitch()) {
        try {
          await widget.safChannel
              .invokeMethod<void>('releaseGrant', {'uri': uri});
        } catch (_) {}
        _resumeCurrent();
        return;
      }
      if (old != null && old != uri) {
        try {
          await widget.safChannel
              .invokeMethod<void>('releaseGrant', {'uri': old});
        } catch (_) {}
      }
      await widget.settings.setTreeUri(uri);
      _changing = false;
      if (_phase == _Boot.setup) {
        // First run: picking is one of three choices on that screen, not the
        // end of it. Continue is what leaves.
        if (mounted) setState(() {});
        return;
      }
      await _enter(uri);
    } on PlatformException {
      // Picker failed to launch (SAF_IO): stay where we are (gate, or the
      // running app on a deliberate change).
      final ctx = _dialogContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
            content: Text("Couldn't open the folder picker — try again")));
      }
    } finally {
      _picking = false;
    }
  }

  /// Switching to a DIFFERENT folder silently shows whatever it holds — an
  /// empty one reads as data loss. Confirm first. Copy undesigned — flagged.
  Future<bool> _confirmSwitch() async {
    final ctx = _dialogContext;
    if (ctx == null) return true;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Switch to this folder?'),
        content: const Text(
            'Your recipes stay in the current folder — nothing is moved or '
            'deleted. The app will show what the new folder holds.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dctx, true),
            child: const Text('Switch folder'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _resumeCurrent() {
    if (!_changing || _store == null || !mounted) return;
    setState(() {
      _changing = false;
      _phase = _Boot.ready;
    });
  }

  Future<void> _enter(String uri) async {
    final store = SafFolderStore(
      treeUri: uri,
      imageCache: widget.imageCache,
      channel: widget.safChannel,
    );
    final localPantry = widget.localPantry;
    final pantryCache = widget.pantryImageCache;
    final pantry = localPantry != null && pantryCache != null
        ? SafPantryStore(
            treeUri: uri, imageCache: pantryCache, channel: widget.safChannel)
        : null;
    // Pantry migration has no done-flag: the drained old dir is the flag, so
    // this stays a cheap exists() on every later boot.
    final pantryPending =
        localPantry != null && await localPantry.root.exists();
    if (!widget.settings.migrationDone || pantryPending) {
      if (mounted) setState(() => _phase = _Boot.migrating);
      try {
        if (!widget.settings.migrationDone) {
          await migrateLocalToSaf(widget.localStore, store,
              settings: widget.settings);
        }
        if (pantryPending && pantry != null) {
          await migratePantryToSaf(localPantry, pantry);
        }
      } on GrantLostException {
        // Flag stays unset / old dir stays — re-pick, then both run again.
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
        _pantry = pantry;
        _phase = _onboardingPending ? _Boot.slides : _Boot.ready;
      });
    }
  }

  void _onGrantLost() {
    if (!mounted || _phase != _Boot.ready) return;
    setState(() {
      _lost = true;
      _changing = false;
      _store = null;
      _pantry = null;
      _phase = _Boot.gate;
    });
  }

  /// Deliberate change (Storage → "Change folder"): straight to the system
  /// picker — no gate interstitial. The gate screen's only jobs are first run
  /// and lost grant, where no app exists behind it; here the app itself is the
  /// "keep current folder" state, so backing out of the picker just returns
  /// (Arnar's UX call, asked twice, 2026-08-06). The app stays visible under
  /// the picker overlay; _changing keeps _store so every cancel path resumes.
  void _changeFolder() {
    if (!mounted || _phase != _Boot.ready) return;
    _lost = false;
    _changing = true; // keep _store: cancelling returns to the app
    _pick();
  }

  /// The setup screen rebuilds on its own listenables rather than through the
  /// MaterialApp's: units and theme must reflect a tap instantly, and theme
  /// repaints the whole gate app around it.
  Widget _setupScreen() {
    final uri = widget.settings.treeUri;
    final units = widget.units;
    final themePref = widget.themeMode;
    Widget build(UnitSystem u, ThemeMode t) => FirstRunSetupScreen(
          folderName: folderDisplayName(uri),
          onPickFolder: _pick,
          units: u,
          onUnits: widget.onUnits ?? (_) {},
          themeMode: t,
          onThemeMode: widget.onThemeMode ?? (_) {},
          // Disabled until a folder exists — Continue must never advance into
          // an app with nowhere to save.
          onContinue: uri == null ? null : () => _enter(uri),
        );
    Widget withTheme(UnitSystem u) => themePref == null
        ? build(u, ThemeMode.system)
        : ValueListenableBuilder<ThemeMode>(
            valueListenable: themePref, builder: (_, t, _) => build(u, t));
    return units == null
        ? withTheme(UnitSystem.asWritten)
        : ValueListenableBuilder<UnitSystem>(
            valueListenable: units, builder: (_, u, _) => withTheme(u));
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Boot.ready) {
      // Keyed by folder: switching to a DIFFERENT folder must remount the
      // whole app subtree so every provider rebinds to the new store — the
      // old gate detour did that by accident (the subtree unmounted during
      // the gate phase); the direct picker path keeps the tree alive, so the
      // key does it on purpose. Same-folder re-pick keeps state and stays on
      // the screen the user was on.
      return KeyedSubtree(
        key: ValueKey(widget.settings.treeUri),
        child: widget.appBuilder(_store!, _pantry, _onGrantLost, _changeFolder),
      );
    }
    final gateHome = switch (_phase) {
      _Boot.welcome => WelcomeScreen(
          onContinue: () => setState(() => _phase = _Boot.setup),
        ),
      _Boot.setup => _setupScreen(),
      _Boot.gate => FolderGate(
          lost: _lost,
          onPick: _pick,
          onCancel: _changing && _store != null ? _resumeCurrent : null,
        ),
      _Boot.slides => SlidesScreen(onDone: _finishOnboarding),
      _ => _Busy(
          label: _phase == _Boot.migrating ? 'Moving your recipes in…' : null),
    };
    MaterialApp app(ThemeMode mode, Locale? locale) => MaterialApp(
          title: 'MyReciBook',
          navigatorKey: _nav,
          theme: rbLightTheme(),
          darkTheme: rbDarkTheme(),
          themeMode: mode,
          // null = follow the phone; MaterialApp resolves it against the
          // supported list itself.
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kOfferedLocales,
          home: gateHome,
        );
    final themePref = widget.themeMode;
    final localePref = widget.locale;
    Widget withLocale(ThemeMode mode) => localePref == null
        ? app(mode, null)
        : ValueListenableBuilder<Locale?>(
            valueListenable: localePref, builder: (_, l, _) => app(mode, l));
    if (themePref == null) return withLocale(ThemeMode.system);
    return ValueListenableBuilder<ThemeMode>(
        valueListenable: themePref, builder: (_, mode, _) => withLocale(mode));
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
  const FolderGate(
      {super.key, required this.onPick, this.lost = false, this.onCancel});

  final VoidCallback onPick;
  final bool lost;

  /// Present only during a deliberate change-folder — the way back to the
  /// running app. Copy undesigned — flagged.
  final VoidCallback? onCancel;

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
                          // Not "on this phone": SafBridge sends a plain
                          // OPEN_DOCUMENT_TREE, so the picker already lists
                          // the SD card and any cloud app exposing a writable
                          // folder. The old line was narrower than the code.
                          : 'Pick a folder for your recipes. Every one is '
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
              if (onCancel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextButton(
                    key: const Key('keep-folder-button'),
                    onPressed: onCancel,
                    child: const Text('Keep current folder'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
