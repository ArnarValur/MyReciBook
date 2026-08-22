// Settings — 6a (turn 6): "three blocks, nothing else". The mock draws a
// pushed page with a back arrow; ours is the bar's Settings tab, so the tab
// stays and the arrow goes (established adaptation). Blocks: Theme (segmented
// pill), Storage (one truthful row → the 6e Storage screen), About (licenses)
// + the centered version footer.
//
// Deliberately absent, per the 6a annotation — don't let them creep in:
// accounts (never), notification toggles, and the link-import switch
// (post-alpha). The telemetry ban has ONE recorded exception since 2026-08-21:
// an opt-in crash-report switch, off by default (audit H1). Analytics is still
// never.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:provider/provider.dart';

import '../data/crash_log.dart';
import '../features.dart';
import '../domain/app_language.dart';
import '../domain/units.dart';
import '../l10n/l10n.dart';
import '../version.dart';
import 'crash_reporting_model.dart';
import 'diary/diary_goal_screen.dart';
import 'diary/diary_model.dart';
import 'storage_model.dart';
import 'theme.dart';
import 'theme_model.dart';
import 'language_model.dart';
import 'language_screen.dart';
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
    final crash = context.read<CrashReportingModel>();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final scheme = ctx.scheme;
        final entries = log.entries;
        return AlertDialog(
          title: Text(entries.isEmpty
              ? ctx.l10n.errorLogTitle
              : ctx.l10n.errorLogTitleCount(entries.length)),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty
                ? Text(ctx.l10n.errorLogEmpty,
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
            // The dashboard shows nothing until a first report arrives, which
            // looks exactly like being broken. This proves the pipe.
            if (crash.enabled && crash.hasSink)
              TextButton(
                onPressed: () {
                  // Both strings read off the dialog's context BEFORE the pop
                  // — after it, ctx is unmounted and the lookup would throw.
                  final l10n = ctx.l10n;
                  final sent = crash.sendTestReport();
                  Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(sent
                            ? l10n.errorLogTestSent
                            : l10n.errorLogReportsOff)));
                  }
                },
                child: Text(ctx.l10n.errorLogSendTest),
              ),
            if (entries.isNotEmpty) ...[
              TextButton(
                onPressed: () async {
                  await log.clear();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(ctx.l10n.errorLogClear),
              ),
              TextButton(
                onPressed: () async {
                  // Read before the await and the pop, same reason.
                  final copied = ctx.l10n.errorLogCopied;
                  await Clipboard.setData(ClipboardData(text: log.export()));
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  // The OUTER context crossed the await too — guard it
                  // separately; the tab can unmount while the copy runs.
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(copied)));
                  }
                },
                child: Text(ctx.l10n.errorLogCopyAll),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(ctx.l10n.commonClose),
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
    final languageModel = context.watch<LanguageModel>();
    final storage = context.watch<StorageModel>();

    Widget row({
      required IconData icon,
      required String title,
      String? caption,
      VoidCallback? onTap,
      Key? key,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            key: key,
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
            child: Text(context.l10n.settingsTitle,
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22)),
          ),
          Expanded(
            child: ListView(
              // Bottom clearance for the glass bar, grocery-tab convention.
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
              children: [
                SectionLabel(context.l10n.sectionTheme),
                const SizedBox(height: 8),
                Container(
                  key: const Key('settings-theme-control'),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    themeSegment(ThemeMode.system, context.l10n.themeSystem),
                    themeSegment(ThemeMode.light, context.l10n.themeLight),
                    themeSegment(ThemeMode.dark, context.l10n.themeDark),
                  ]),
                ),
                const SizedBox(height: 20),
                // Units (Arnar 2026-08-18): three states, not a checkbox —
                // "As written" must exist so nothing converts by default.
                SectionLabel(context.l10n.sectionUnits),
                const SizedBox(height: 8),
                Container(
                  key: const Key('settings-units-control'),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999)),
                  child: Row(children: [
                    unitSegment(
                        UnitSystem.asWritten, context.l10n.unitsAsWritten),
                    unitSegment(UnitSystem.metric, context.l10n.unitsMetric),
                    unitSegment(
                        UnitSystem.imperial, context.l10n.unitsImperial),
                  ]),
                ),
                const SizedBox(height: 20),
                // Language: hidden entirely until a second language is
                // actually finished (kLanguageChoiceExists). A row that opens
                // a list of one, or that switches you into a screen of mixed
                // Icelandic and English, is worse than no row at all.
                // A row to a pushed list, the Storage shape — eleven
                // languages plus System never fit a segmented pill. The row's
                // title IS the current language, in its own name.
                if (kLanguageChoiceExists) ...[
                  SectionLabel(context.l10n.sectionLanguage),
                  const SizedBox(height: 8),
                  row(
                    // Keyed: the row's title is 'System' before a choice, which
                    // also labels a Theme segment — a bare text finder is two.
                    key: const Key('settings-language-row'),
                    icon: Icons.language_rounded,
                    title: languageModel.language == AppLanguage.system
                        ? context.l10n.languageSystem
                        : appLanguageEndonym(languageModel.language),
                    onTap: () =>
                        Navigator.of(context).push<void>(MaterialPageRoute<void>(
                            builder: (_) => ChangeNotifierProvider<LanguageModel>
                                .value(
                              value: context.read<LanguageModel>(),
                              child: const LanguageScreen(),
                            ))),
                  ),
                  const SizedBox(height: 8),
                ],
                if (kDiaryEnabled) ...[
                  SectionLabel(context.l10n.sectionDiary),
                  const SizedBox(height: 8),
                  row(
                    icon: Icons.flag_outlined,
                    title: context.l10n.diaryDailyGoal,
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
                SectionLabel(context.l10n.sectionStorage),
                const SizedBox(height: 8),
                row(
                  icon: Icons.cloud_rounded,
                  title: context.l10n.storageWhereRecipesLive,
                  // Truthful one-liner (6a): 'This phone' alone, or
                  // 'This phone + <Provider> · synced X ago' when proven.
                  caption: storage.settingsSummary(),
                  onTap: onOpenStorage,
                ),
                const SizedBox(height: 8),
                // The 6a annotation banned telemetry toggles. This is the one
                // deliberate exception, added when the app stopped being
                // Arnar-only (audit H1): a crash nobody can see is a crash
                // nobody fixes. It is opt-in, it is a switch, and the local
                // error log below keeps working either way.
                SectionLabel(context.l10n.sectionCrashReports),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final crash = context.watch<CrashReportingModel>();
                  return SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.l10n.crashReportsSend,
                        style: theme.textTheme.bodyLarge),
                    subtitle: Text(
                      crash.hasSink
                          ? context.l10n.crashReportsCaption
                          // Honest rather than silently inert: no Firebase in
                          // this build, so the switch has nowhere to send.
                          : context.l10n.crashReportsUnavailable,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    value: crash.enabled && crash.hasSink,
                    onChanged:
                        crash.hasSink ? (v) => crash.setEnabled(v) : null,
                  );
                }),
                const SizedBox(height: 8),
                SectionLabel(context.l10n.sectionAbout),
                const SizedBox(height: 8),
                row(
                  icon: Icons.description_outlined,
                  title: context.l10n.aboutLicenses,
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
