// Settings tab. On the bar and in the drawer by design (turn-4 navItems, 5c),
// but NO settings screen exists in any mockup (turn-5 "Try next: settings
// screen") — so this whole surface is a DEVIATION, for design to draw:
// undesigned-minimal-until-drawn, the least an alpha tester needs, rendered
// in the house skin (SectionLabel + TokenCard rows). Element flags:
// - Theme choice (System / Light / Dark): undesigned-minimal-until-drawn.
//   Persisted via AppSettings, applied live through ThemeModel → themeMode.
// - Storage row: undesigned-minimal-until-drawn. Truthful summary only
//   (StorageModel.drawerSummary) → the existing 3h StorageScreen.
// - About (licenses + version footer): undesigned-minimal-until-drawn.
//   Licenses = the standard Flutter page (bundled-font OFL entries are
//   registered in main); footer reuses the 5c drawer language verbatim.
// Nothing else on purpose: no accounts (never), no telemetry (D8), no
// notification toggles; the D9 link-import door is post-alpha and absent.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../version.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'theme_model.dart';
import 'widgets/skin.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, this.folderName, this.onOpenStorage});

  /// Display name of the picked recipes folder (truthful storage summary).
  final String? folderName;

  /// Routes to the storage screen (3h) — the shell's existing wiring.
  final VoidCallback? onOpenStorage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final themeModel = context.watch<ThemeModel>();
    final storage = context.watch<StorageModel>();

    Widget row({
      required IconData icon,
      required String title,
      String? caption,
      Widget? trailing,
      VoidCallback? onTap,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: TokenCard(
              padding: const EdgeInsets.all(13),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12)),
                  child:
                      Icon(icon, size: 21, color: scheme.onSurfaceVariant),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontSize: 14.5)),
                        if (caption != null) ...[
                          const SizedBox(height: 2),
                          Text(caption,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ],
                      ]),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: scheme.onSurfaceVariant),
              ]),
            ),
          ),
        );

    // One selectable card per mode, storage-screen option treatment.
    Widget themeOption(ThemeMode mode, IconData icon, String label) {
      final selected = themeModel.mode == mode;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => themeModel.setMode(mode),
          child: TokenCard(
            selected: selected,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Icon(icon,
                  size: 21,
                  color:
                      selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(height: 5),
              Text(label,
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant)),
            ]),
          ),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Text('Settings',
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
          ),
          Expanded(
            child: ListView(
              // Bottom clearance for the glass bar, grocery-tab convention.
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
              children: [
                const SectionLabel('Appearance'),
                const SizedBox(height: 8),
                Row(children: [
                  themeOption(ThemeMode.system,
                      Icons.brightness_auto_rounded, 'System'),
                  const SizedBox(width: 10),
                  themeOption(
                      ThemeMode.light, Icons.light_mode_rounded, 'Light'),
                  const SizedBox(width: 10),
                  themeOption(
                      ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
                ]),
                const SizedBox(height: 20),
                const SectionLabel('Storage'),
                const SizedBox(height: 8),
                row(
                  icon: storage.active != null
                      ? Icons.cloud_done_rounded
                      : Icons.smartphone_rounded,
                  title: 'Where your recipes live',
                  // Same truthful summary as the drawer row — never a state
                  // that isn't real.
                  caption: storage.drawerSummary(folderName: folderName),
                  onTap: onOpenStorage,
                ),
                const SizedBox(height: 8),
                const SectionLabel('About'),
                const SizedBox(height: 8),
                row(
                  icon: Icons.description_outlined,
                  title: 'Open source licenses',
                  onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'MyReciBook',
                      applicationVersion: kAppVersion),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text('MyReciBook $kAppVersion · you own this copy',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11, color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
