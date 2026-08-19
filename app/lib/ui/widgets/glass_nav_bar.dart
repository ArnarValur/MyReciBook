// Floating glass pill NavBar (turn-4 shell, confirmed by turn 5): 56dp pill
// inside a 64dp hint (FAB overhang), 16dp above the bottom edge; the host
// scaffold sets extendBody so content scrolls under the glass.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../features.dart';
import '../theme.dart';
import 'logo_mark.dart';
import 'skin.dart';

class GlassNavBar extends StatelessWidget {
  const GlassNavBar(
      {super.key,
      required this.active,
      this.onTab,
      this.onFab,
      this.queueBadge = 0});

  final int active;
  final ValueChanged<int>? onTab;

  /// Center gradient FAB — the import door (3a) from every tab.
  final VoidCallback? onFab;

  /// Imports needing attention. With the Unlock tab live (slot 2 since
  /// 2026-08-15) the count sits on Cookbook — home of the attention strip
  /// that reopens the queue; with the flag off it sits on the Queue tab as
  /// before. 0 hides the dot.
  final int queueBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final rb = context.rb;

    // `iconBuilder` lets a slot draw something that is not a Material glyph —
    // Cookbook uses the logo's book so the tab and the app icon are one mark.
    Widget item(int i, IconData icon, String label,
        {int badge = 0, Widget Function(Color color)? iconBuilder}) {
      final selected = i == active;
      final color = selected ? scheme.primary : scheme.onSurfaceVariant;
      Widget ic = iconBuilder?.call(color) ??
          Icon(icon, size: 22, fill: selected ? 1 : 0, color: color);
      if (badge > 0) {
        ic = Badge.count(
            count: badge,
            backgroundColor: scheme.primary,
            textColor: scheme.onPrimary,
            child: ic);
      }
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTab == null ? null : () => onTab!(i),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ic,
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(fontSize: 10.5, letterSpacing: 0.2, color: color)),
          ]),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: SizedBox(
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: rb.glassFill,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: rb.glassBorder),
                    ),
                    child: Row(children: [
                      item(0, Icons.menu_book_rounded, 'Cookbook',
                          badge: kUnlockTabEnabled ? queueBadge : 0,
                          iconBuilder: (color) => LogoMark(
                              size: 22, color: color, withSteam: false)),
                      item(1, Icons.checklist_rounded, 'Grocery'),
                      const SizedBox(width: 60),
                      // Slot 2 history: Meal plan (engine-less, hidden) →
                      // Import queue (2026-08-06 hands-on) → Unlock
                      // (2026-08-15, Arnar: sell the app here; the queue
                      // lives on as the pushed batch route + Cookbook strip)
                      // → Pantry POC borrowing the slot on dev builds
                      // (2026-08-17, kPantryEnabled) → "Food": the diary and
                      // the pantry behind one segmented control
                      // (2026-08-19, kDiaryEnabled).
                      if (kDiaryEnabled)
                        item(2, Icons.restaurant_rounded, 'Food')
                      else if (kPantryEnabled)
                        item(2, Icons.kitchen_rounded, 'Pantry')
                      else if (kUnlockTabEnabled)
                        item(2, Icons.lock_open_rounded, 'Unlock')
                      else
                        item(2, Icons.download_rounded, 'Queue',
                            badge: queueBadge),
                      item(3, Icons.settings_rounded, 'Settings'),
                    ]),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: GradientFab(onPressed: onFab ?? () {}),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
