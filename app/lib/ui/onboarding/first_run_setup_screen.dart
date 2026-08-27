// Screen 2 of the first-run flow: the three choices that are annoying to hunt
// for later — where recipes live, which units to show, light or dark.
//
// Arnar's shape (2026-08-27): "first time settings page instead — choose
// location, choose default metrics, choose theme, boom." Three rows, kept to
// three. Everything else already has a home in Settings and belongs there;
// a first-run page that grows into a second settings screen is a page nobody
// finishes.
//
// The folder is the only required one. Units and theme both have a working
// default, so a user who ignores them still lands somewhere sane.

import 'package:flutter/material.dart';

import '../../domain/units.dart';
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
  });

  /// Display name of the chosen folder, or null while none is chosen —
  /// which is also what keeps [onContinue] disabled.
  final String? folderName;
  final VoidCallback onPickFolder;

  final UnitSystem units;
  final ValueChanged<UnitSystem> onUnits;

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeMode;

  /// Null until a folder is chosen.
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final picked = folderName != null;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set up MyReciBook',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontSize: 22, height: 1.25)),
                  const SizedBox(height: 8),
                  Text(
                    'Three quick choices. You can change all of them later in '
                    'Settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant, height: 1.5),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 16, 28, 16),
                children: [
                  _Section(
                    title: 'Where your recipes live',
                    // The one honest correction to the old gate copy: the
                    // Android picker was never restricted to internal storage
                    // (SafBridge sends a plain OPEN_DOCUMENT_TREE), so it
                    // already lists the SD card and any cloud app that
                    // exposes a writable folder. Saying "on this phone" was
                    // narrower than the code.
                    body: 'Every recipe is saved as a plain file in a folder '
                        'you choose — your folder, your files. The app reads '
                        'and writes only in there.',
                    child: _FolderRow(
                      folderName: folderName,
                      onPick: onPickFolder,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Section(
                    title: 'Units',
                    body: 'How quantities are shown. As written keeps each '
                        'recipe exactly as its author wrote it.',
                    child: _Choices<UnitSystem>(
                      value: units,
                      onChanged: onUnits,
                      options: const {
                        UnitSystem.asWritten: 'As written',
                        UnitSystem.metric: 'Metric',
                        UnitSystem.imperial: 'Imperial',
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Section(
                    title: 'Appearance',
                    body: 'System follows your phone.',
                    child: _Choices<ThemeMode>(
                      value: themeMode,
                      onChanged: onThemeMode,
                      options: const {
                        ThemeMode.system: 'System',
                        ThemeMode.light: 'Light',
                        ThemeMode.dark: 'Dark',
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!picked)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Choose a folder to continue.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  GradientButton(
                    key: const Key('setup-continue-button'),
                    label: 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: onContinue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body, required this.child});

  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(body,
            style: theme.textTheme.bodySmall?.copyWith(
                color: context.scheme.onSurfaceVariant, height: 1.5)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.folderName, required this.onPick});

  final String? folderName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final name = folderName;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('setup-choose-folder'),
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(name == null ? Icons.folder_open_rounded : Icons.folder_rounded,
                  size: 22, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name ?? 'Choose folder',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: name == null ? FontWeight.w600 : FontWeight.w500),
                ),
              ),
              if (name != null)
                Text('Change',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: scheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row of segmented choices. Generic so units and theme share one control
/// instead of two that drift.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.value,
    required this.onChanged,
    required this.options,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final Map<T, String> options;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final e in options.entries)
          ButtonSegment<T>(value: e.key, label: Text(e.value)),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
