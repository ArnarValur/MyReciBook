// M3 modal navigation drawer (5c). The bottom bar keeps the four daily
// surfaces; the drawer holds data + utility — nothing lives only here except
// Help. Engine-less rows (Import queue, Your copy, Help & feedback) render the
// designed row but perform no action; trailing state only ever shows what is
// true — the Storage trailing comes from StorageModel.drawerSummary, so it
// says "This phone" locally and "Drive · synced X ago" only when that
// actually happened (turn-5 5c honesty).

import 'package:flutter/material.dart';

import 'theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
    this.queuedImports = 0,
    this.storageLabel = 'This phone',
    this.storageCloud = false,
    this.onOpenStorage,
  });

  final int activeTab;
  final ValueChanged<int> onSelectTab;

  /// Real count of shares queued behind an open import; 0 hides the badge.
  final int queuedImports;

  /// Truthful Storage row trailing (StorageModel.drawerSummary).
  final String storageLabel;

  /// Connector active → the 5c cloud_done glyph; otherwise the phone.
  final bool storageCloud;

  /// Routes to the storage screen (3h).
  final VoidCallback? onOpenStorage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    Widget small(String text) => Text(text,
        style: theme.textTheme.bodySmall
            ?.copyWith(fontSize: 11.5, color: scheme.onSurfaceVariant));

    Widget badge(int n) => Container(
          constraints: const BoxConstraints(minWidth: 20),
          height: 20,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: scheme.primary, borderRadius: BorderRadius.circular(999)),
          child: Text('$n',
              style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onPrimary)),
        );

    Widget row({
      required IconData icon,
      required String label,
      bool active = false,
      Widget? trailing,
      VoidCallback? onTap,
    }) {
      final fg = active ? scheme.onSecondaryContainer : scheme.onSurfaceVariant;
      final child = Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: active
            ? BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(999))
            : null,
        child: Row(children: [
          Icon(icon, size: 22, fill: active ? 1 : 0, color: fg),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: fg)),
          ),
          ?trailing,
        ]),
      );
      if (onTap == null) return child;
      return InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          Navigator.of(context).pop(); // close the drawer, then act
          onTap();
        },
        child: child,
      );
    }

    Widget divider() => Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        );

    const gap = SizedBox(height: 4);

    return Drawer(
      width: 294,
      backgroundColor: scheme.surfaceContainerLowest,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 22, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Row(children: [
                  Icon(Icons.menu_book_rounded,
                      size: 22, fill: 1, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text('MyReciBook',
                      style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.36,
                          color: scheme.primary)),
                ]),
              ),
              row(
                  icon: Icons.menu_book_rounded,
                  label: 'Cookbook',
                  active: activeTab == 0,
                  onTap: () => onSelectTab(0)),
              gap,
              row(
                  icon: Icons.checklist_rounded,
                  label: 'Grocery',
                  active: activeTab == 1,
                  onTap: () => onSelectTab(1)),
              gap,
              row(
                  icon: Icons.calendar_month_rounded,
                  label: 'Meal plan',
                  active: activeTab == 2,
                  onTap: () => onSelectTab(2)),
              gap,
              // D5 cut the inbox; the queue engine is post-alpha. The badge is
              // backed by the only real queue: shares held behind an open import.
              row(
                  icon: Icons.download_rounded,
                  label: 'Import queue',
                  trailing: queuedImports > 0 ? badge(queuedImports) : null),
              divider(),
              // 5b exists in design only — no entitlement engine, no action.
              // DEVIATION from 5c row 5, for design to ratify: the designed
              // "owned" trailing is dropped — an ownership claim the alpha
              // cannot honestly make (the spec flags untrue ones as HIGH).
              row(icon: Icons.verified_rounded, label: 'Your copy'),
              gap,
              row(
                  icon: storageCloud
                      ? Icons.cloud_done_rounded
                      : Icons.smartphone_rounded,
                  label: 'Storage',
                  trailing: small(storageLabel),
                  onTap: onOpenStorage),
              gap,
              row(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  active: activeTab == 3,
                  onTap: () => onSelectTab(3)),
              divider(),
              // The one drawer-only destination; its screen is undesigned.
              row(icon: Icons.help_rounded, label: 'Help & feedback'),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text('MyReciBook 1.0 · you own this copy',
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
