// Nav slot 3 hosts two surfaces that are one idea: the Diary (what you ate)
// and the Pantry (what you can eat). A segmented control switches them, so
// the daily-driver screen is one tap from the bar and the shelf never gets
// buried — Arnar's call, 2026-08-19.
//
// Both children keep their own scroll position: an IndexedStack, not a
// rebuild, so walking back from the pantry lands on the same day you left.

import 'package:flutter/material.dart';

import '../pantry/pantry_tab.dart';
import '../theme.dart';
import 'diary_tab.dart';

class FoodTab extends StatefulWidget {
  const FoodTab({super.key});

  @override
  State<FoodTab> createState() => _FoodTabState();
}

class _FoodTabState extends State<FoodTab> {
  int _segment = 0;

  /// Built on first visit only — the pantry's initial listAll should not run
  /// because the diary happens to be on screen.
  final _built = [true, false];

  void _select(int i) {
    if (i == _segment) return;
    setState(() {
      _segment = i;
      _built[i] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = _Segmented(active: _segment, onTap: _select);
    return IndexedStack(
      index: _segment,
      children: [
        DiaryTab(header: header),
        _built[1]
            ? PantryTab(header: header)
            : const SizedBox.shrink(),
      ],
    );
  }
}

/// Two pills in a track — the app's chip language at section scale.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.active, required this.onTap});

  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        _pill(context, 0, 'Diary', Icons.event_note_rounded),
        _pill(context, 1, 'Pantry', Icons.kitchen_rounded),
      ]),
    );
  }

  Widget _pill(BuildContext context, int index, String label, IconData icon) {
    final scheme = context.scheme;
    final selected = index == active;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? scheme.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected ? context.rb.cardShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? scheme.primary : scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color:
                        selected ? scheme.onSurface : scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
