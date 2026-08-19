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
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../data/crash_log.dart';
import '../features.dart';
import '../domain/units.dart';
import '../version.dart';
import 'diary/diary_goal_screen.dart';
import 'diary/diary_model.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'theme_model.dart';
import 'units_model.dart';
import 'widgets/skin.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key, this.folderName, this.onOpenStorage});

  /// Display name of the picked recipes folder (unused by the 6a caption —
  /// kept so the shell wiring stays uniform with the drawer row).
  final String? folderName;

  /// Routes to the Storage screen (6e) — the shell's existing wiring.
  final VoidCallback? onOpenStorage;

  void _showErrorLog(BuildContext context) {
    final log = context.read<CrashLog>();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = ctx.scheme;
        final entries = log.entries;
        return AlertDialog(
          title: Text(entries.isEmpty
              ? 'Error log'
              : 'Error log (${entries.length})'),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty
                ? Text('No captured errors.',
                    style: Theme.of(ctx)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant))
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${e['at']}',
                              style: Theme.of(ctx).textTheme.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('${e['error']}',
                              style: Theme.of(ctx).textTheme.bodySmall),
                        ],
                      );
                    },
                  ),
          ),
          actions: [
            if (entries.isNotEmpty) ...[
              TextButton(
                onPressed: () async {
                  await log.clear();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: log.export()));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  // The OUTER context crossed the await too — guard it
                  // separately; the tab can unmount while the copy runs.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Error log copied — paste it to Arnar')));
                  }
                },
                child: const Text('Copy all'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final themeModel = context.watch<ThemeModel>();
    final unitsModel = context.watch<UnitsModel>();
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
    Widget segment(
        {required bool selected,
        required String label,
        required VoidCallback onTap}) {
      return Expanded(
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
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

    Widget themeSegment(ThemeMode mode, String label) => segment(
        selected: themeModel.mode == mode,
        label: label,
        onTap: () => themeModel.setMode(mode));

    Widget unitSegment(UnitSystem system, String label) => segment(
        selected: unitsModel.system == system,
        label: label,
        onTap: () => unitsModel.setSystem(system));

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
                // Units (Arnar 2026-08-18): three states, not a checkbox —
                // "As written" must exist so nothing converts by default.
                const SectionLabel('Units'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    unitSegment(UnitSystem.asWritten, 'As written'),
                    unitSegment(UnitSystem.metric, 'Metric'),
                    unitSegment(UnitSystem.imperial, 'US'),
                  ]),
                ),
                const SizedBox(height: 20),
                if (kDiaryEnabled) ...[
                  const SectionLabel('Diary'),
                  const SizedBox(height: 8),
                  row(
                    icon: Icons.flag_outlined,
                    title: 'Daily goal',
                    caption: context.watch<DiaryModel>().goalSummary,
                    onTap: () =>
                        Navigator.of(context).push<void>(MaterialPageRoute<void>(
                            builder: (_) => ChangeNotifierProvider<DiaryModel>
                                .value(
                              value: context.read<DiaryModel>(),
                              child: const DiaryGoalScreen(),
                            ))),
                  ),
                  const SizedBox(height: 8),
                ],
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
                  // Quiet door keeping 6a's "three blocks, nothing else":
                  // long-press opens the local error log so a tester can copy
                  // evidence out — no telemetry (D8). Unlike the debug-only
                  // dev gallery this SHIPS in release (testers are the point),
                  // and it is undiscoverable by design — the closed-test
                  // instructions must name the long-press. UNDESIGNED —
                  // surface shape to ratify at the next design turn.
                  child: GestureDetector(
                    onLongPress: () => _showErrorLog(context),
                    // Opaque + padded: the tester instruction is "long-press
                    // the version footer" — a miss by a few px must not read
                    // as "the door doesn't exist".
                    behavior: HitTestBehavior.opaque,
                    // owned stays false until a purchase receipt exists (6a):
                    // the footer "drops 'you own this copy' until the receipt
                    // makes it true".
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                      child: Text(versionFooter(owned: false),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11, color: scheme.onSurfaceVariant)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
