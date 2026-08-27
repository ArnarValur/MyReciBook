// Screen 1b of the first-run flow — Claude Design onboarding mockup, option 1b
// ("Make it yours"). Three choices on one page, no skip.
//
// Where recipes live is drawn as three cards, and that is the answer to "why
// can't I pick Drive or Dropbox?": neither exposes a writable folder tree to
// Android's picker, so neither can BE the location. The phone folder is the
// location; the two cloud cards connect a mirror beside it. One page, base
// plus optional connect, exactly as drawn.
//
// Two deliberate departures from the mockup, both Arnar's call 2026-08-27:
//   · "This phone" starts unchosen and opens the system picker, because the
//     app genuinely cannot run until a real folder is granted. The mockup's
//     "zero setup" caption would have been a lie.
//   · Units offers Metric and Imperial as drawn. The app's third mode,
//     "as written", stays in Settings.

import 'package:flutter/material.dart';

import '../../domain/units.dart';
import '../storage_model.dart';
import '../theme.dart';
import 'onboarding_scaffold.dart';

class FirstRunSetupScreen extends StatelessWidget {
  const FirstRunSetupScreen({
    super.key,
    required this.folderName,
    required this.onPickFolder,
    required this.units,
    required this.onUnits,
    required this.themeMode,
    required this.onThemeMode,
    required this.onContinue,
    this.storage,
  });

  /// Display name of the granted folder, null while none is chosen — which is
  /// also what keeps [onContinue] disabled.
  final String? folderName;
  final VoidCallback onPickFolder;

  final UnitSystem units;
  final ValueChanged<UnitSystem> onUnits;

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeMode;

  /// Null until a folder is chosen.
  final VoidCallback? onContinue;

  /// The connector model, for the two cloud cards. Null (tests) draws them
  /// in their unconfigured state and taps do nothing.
  final StorageModel? storage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make it yours',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 23, height: 1.25, letterSpacing: -0.23)),
                  const SizedBox(height: 5),
                  Text('Three choices. Everything else has good defaults.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 13.5, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                children: [
                  const _SectionLabel('WHERE YOUR RECIPES LIVE'),
                  const SizedBox(height: 10),
                  _LocationCard(
                    key: const Key('setup-choose-folder'),
                    icon: Icons.phone_android_rounded,
                    title: folderName ?? 'This phone',
                    subtitle: folderName == null
                        ? 'choose a folder · works offline'
                        : 'your folder · works offline',
                    selected: folderName != null,
                    onTap: onPickFolder,
                  ),
                  const SizedBox(height: 10),
                  _ConnectorCard(
                    provider: StorageModel.drive,
                    icon: Icons.add_to_drive_rounded,
                    title: 'Google Drive',
                    subtitle: "app folder only — we can't see the rest",
                    storage: storage,
                  ),
                  const SizedBox(height: 10),
                  _ConnectorCard(
                    provider: StorageModel.dropbox,
                    icon: Icons.cloud_rounded,
                    title: 'Dropbox',
                    subtitle: 'app folder only',
                    storage: storage,
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('UNITS'),
                  const SizedBox(height: 8),
                  _PillToggle<UnitSystem>(
                    key: const Key('setup-units-toggle'),
                    value: units,
                    onChanged: onUnits,
                    options: const {
                      UnitSystem.metric: 'Metric',
                      UnitSystem.imperial: 'Imperial',
                    },
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('THEME'),
                  const SizedBox(height: 8),
                  _PillToggle<ThemeMode>(
                    key: const Key('setup-theme-toggle'),
                    value: themeMode,
                    onChanged: onThemeMode,
                    options: const {
                      ThemeMode.system: 'System',
                      ThemeMode.light: 'Light',
                      ThemeMode.dark: 'Dark',
                    },
                  ),
                  const SizedBox(height: 16),
                  DottedNote(
                    folderName == null
                        ? 'Pick a folder to continue. All three live in '
                            'Settings — nothing here is final.'
                        : 'All three live in Settings — nothing here is final.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: GradientButton(
                key: const Key('setup-continue-button'),
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
            letterSpacing: 0.9,
            fontWeight: FontWeight.w600,
            color: context.scheme.onSurfaceVariant));
  }
}

/// The shared card shell: icon tile, title, subtitle, trailing slot.
class _Card extends StatelessWidget {
  const _Card({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : context.rb.hairline,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected ? context.rb.glowPrimary : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? scheme.secondaryContainer
                        : scheme.surfaceContainerHigh,
                  ),
                  child: Icon(icon,
                      size: 21,
                      color: selected
                          ? scheme.onSecondaryContainer
                          : scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return _Card(
      icon: icon,
      title: title,
      subtitle: subtitle,
      selected: selected,
      onTap: onTap,
      trailing: selected
          ? Icon(Icons.check_circle, size: 22, color: scheme.primary)
          : Text('Choose',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.primary)),
    );
  }
}

/// A cloud mirror card. Rebuilds on the model so a connect in flight, a
/// failure, and "awaiting keys in this build" are all visible where they
/// happened rather than swallowed.
class _ConnectorCard extends StatelessWidget {
  const _ConnectorCard({
    required this.provider,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.storage,
  });

  final String provider;
  final IconData icon;
  final String title;
  final String subtitle;
  final StorageModel? storage;

  @override
  Widget build(BuildContext context) {
    final model = storage;
    if (model == null) {
      return _Card(
        icon: icon,
        title: title,
        subtitle: subtitle,
        trailing: const _ConnectLabel('Connect', enabled: false),
      );
    }
    return AnimatedBuilder(
      animation: model,
      builder: (context, _) {
        final connected = model.active == provider;
        final busy = model.connecting == provider;
        final unconfigured = model.notConfigured == provider;
        final error = model.connectErrorFor(provider);
        return _Card(
          icon: icon,
          title: title,
          subtitle: unconfigured
              ? 'awaiting keys in this build'
              : error ?? (connected ? 'connected · mirroring' : subtitle),
          selected: connected,
          onTap: connected || busy ? null : () => model.connect(provider),
          trailing: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : connected
                  ? Icon(Icons.check_circle,
                      size: 22, color: context.scheme.primary)
                  : const _ConnectLabel('Connect'),
        );
      },
    );
  }
}

class _ConnectLabel extends StatelessWidget {
  const _ConnectLabel(this.text, {this.enabled = true});

  final String text;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: enabled ? scheme.outline : context.rb.hairline),
      ),
      child: Text(text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: enabled ? scheme.onSurface : scheme.onSurfaceVariant)),
    );
  }
}

/// The mockup's rounded-full segmented track: the selected segment is a raised
/// pill with a check, the rest are flat labels.
class _PillToggle<T> extends StatelessWidget {
  const _PillToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: e.key == value
                        ? scheme.surfaceContainerLowest
                        : Colors.transparent,
                    boxShadow: e.key == value ? context.rb.cardShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (e.key == value) ...[
                        Icon(Icons.check, size: 16, color: scheme.primary),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontSize: 12.5,
                            fontWeight: e.key == value
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: e.key == value
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
