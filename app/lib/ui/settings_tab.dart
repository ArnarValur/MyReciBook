// Settings — 6a (turn 6): "three blocks, nothing else". The mock draws a
// pushed page with a back arrow; ours is the bar's Settings tab, so the tab
// stays and the arrow goes (established adaptation). Blocks: Theme (segmented
// pill), Storage (one truthful row → the 6e Storage screen), About (licenses)
// + the centered version footer.
//
// Deliberately absent, per the 6a annotation — don't let them creep in:
// accounts (never), telemetry, notification toggles, and the link-import
// switch (post-alpha).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../version.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'theme_model.dart';
import 'widgets/skin.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, this.folderName, this.onOpenStorage});

  /// Display name of the picked recipes folder (unused by the 6a caption —
  /// kept so the shell wiring stays uniform with the drawer row).
  final String? folderName;

  /// Routes to the Storage screen (6e) — the shell's existing wiring.
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
                Icon(Icons.chevron_right_rounded,
                    size: 22, color: scheme.onSurfaceVariant),
              ]),
            ),
          ),
        );

    // 6a segmented control: one stadium container, three segments; the active
    // segment is a white pill on light / dark pill on dark
    // (surfaceContainerLowest is exactly that) with a check icon + w600.
    Widget themeSegment(ThemeMode mode, String label) {
      final selected = themeModel.mode == mode;
      return Expanded(
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => themeModel.setMode(mode),
          child: Container(
            height: 38,
            alignment: Alignment.center,
            decoration: selected
                ? BoxDecoration(
                    color: scheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.rb.hairline),
                    boxShadow: context.rb.cardShadow,
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 15, color: scheme.onSurface),
                  const SizedBox(width: 5),
                ],
                Text(label,
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant)),
              ],
            ),
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
                const SectionLabel('Theme'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    themeSegment(ThemeMode.system, 'System'),
                    themeSegment(ThemeMode.light, 'Light'),
                    themeSegment(ThemeMode.dark, 'Dark'),
                  ]),
                ),
                const SizedBox(height: 20),
                const SectionLabel('Storage'),
                const SizedBox(height: 8),
                row(
                  icon: Icons.cloud_rounded,
                  title: 'Where your recipes live',
                  // Truthful one-liner (6a): 'This phone' alone, or
                  // 'This phone + <Provider> · synced X ago' when proven.
                  caption: storage.settingsSummary(),
                  onTap: onOpenStorage,
                ),
                const SizedBox(height: 8),
                const SectionLabel('About'),
                const SizedBox(height: 8),
                row(
                  icon: Icons.description_outlined,
                  title: 'Open-source licenses',
                  onTap: () => showLicensePage(
                      context: context,
                      applicationName: 'MyReciBook',
                      applicationVersion: kAppVersion),
                ),
                const SizedBox(height: 8),
                Center(
                  // owned stays false until a purchase receipt exists (6a):
                  // the footer "drops 'you own this copy' until the receipt
                  // makes it true".
                  child: Text(versionFooter(owned: false),
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
