// Post-alpha design previews — faithful builds of hi-fi 3g/3h/4a/4d with
// the mockups' own demo data. Reachable only through the debug DevGallery.
// Buttons that would need a missing engine explain themselves via SnackBar.
// (3b batch queue was PROMOTED to lib/ui/batch_queue_screen.dart.)
//
// Product guardrails carried from the handoff spec:
// - Paywall states the fair-use cap in writing (constraint 2).
// - Cap screen's top-up DECIDED 2026-08-30 (Arnar): +1200 rescues, $5 flat,
//   never expires (docs/ai-cap-mechanics.md §5). Stays behind [kTopUpEnabled]
//   until the consumable IAP exists.
// - Grocery merge is suggest-and-confirm, never silent (§6.3).

import 'package:flutter/material.dart';

import '../theme.dart';
import '../unlock_tab.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/skin.dart';

/// Product flag, not a debug flag: the top-up pack needs an explicit yes.
const bool kTopUpEnabled = false;

void _notWired(BuildContext context, String what) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what lands post-alpha — design preview only.')));
}

// ── 3g · Paywall ────────────────────────────────────────────────────────────

// The pitch itself was PROMOTED to lib/ui/unlock_tab.dart (the Unlock tab,
// 2026-08-15) — this preview keeps the 3g MODAL shape (close circle, pinned
// CTA, restore line) for the future hard-paywall route, sharing the promoted
// PaywallPitch so the copy can't drift.
class PaywallPreview extends StatelessWidget {
  const PaywallPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: _CloseCircle(),
              ),
              const SizedBox(height: 4),
              const PaywallPitch(),
              const Spacer(),
              FilledButton(
                onPressed: () => _notWired(context, 'Google Play billing'),
                child: const Text('Unlock MyReciBook — $kUnlockPrice'),
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                      text: 'Restore purchase',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: scheme.primary)),
                  const TextSpan(text: ' · Google Play billing'),
                ]),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 3h · Storage setup ──────────────────────────────────────────────────────

class StoragePreview extends StatelessWidget {
  const StoragePreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    Widget option({
      required IconData icon,
      required String title,
      required String caption,
      required Widget trailing,
      bool selected = false,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TokenCard(
            selected: selected,
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: selected
                        ? scheme.secondaryContainer
                        : scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12)),
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
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontSize: 14.5)),
                      const SizedBox(height: 2),
                      Text(caption,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ]),
              ),
              trailing,
            ]),
          ),
        );

    Widget connect() => OutlinedButton(
          onPressed: () => _notWired(context, 'Sync connectors'),
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(82, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14)),
          child: const Text('Connect'),
        );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                const AppBackButton(),
                Text('Storage', style: theme.textTheme.titleLarge),
              ]),
              const SizedBox(height: 4),
              Text('Where should your recipes live?',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(height: 1.25)),
              const SizedBox(height: 5),
              Text('Plain files, one per recipe. Yours.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 14),
              option(
                icon: Icons.smartphone_rounded,
                title: 'This phone',
                caption: 'zero setup · works offline',
                selected: true,
                trailing: Icon(Icons.check_circle_rounded,
                    size: 22, color: scheme.primary),
              ),
              option(
                icon: Icons.add_to_drive_rounded,
                title: 'Google Drive',
                caption: "app folder only — we can't see the rest",
                trailing: connect(),
              ),
              option(
                icon: Icons.cloud_rounded,
                title: 'Dropbox',
                caption: 'app folder only',
                trailing: connect(),
              ),
              const SectionLabel('What a recipe looks like on disk'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12)),
                child: DefaultTextStyle(
                  style: const TextStyle(
                      fontFamily: 'monospace', fontSize: 11.5, height: 1.65),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MyReciBook/recipes/creamy-garlic-pasta',
                            style: TextStyle(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600)),
                        Text('{ "title": "Creamy garlic pasta",',
                            style:
                                TextStyle(color: scheme.onSurfaceVariant)),
                        Text('  "servings": 4, "ingredients": [ … ] }',
                            style:
                                TextStyle(color: scheme.onSurfaceVariant)),
                      ]),
                ),
              ),
              const SizedBox(height: 12),
              const DashedInfoCard(
                  text:
                      'Move, export or leave anytime. If MyReciBook vanished tomorrow, your recipes wouldn\'t.'),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Text('Continue'),
                label: const Icon(Icons.arrow_forward_rounded, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 4a · Grocery list ───────────────────────────────────────────────────────

class GroceryPreview extends StatelessWidget {
  const GroceryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    Widget row(String qty, String item,
        {bool checked = false,
        String? trailing,
        bool staple = false,
        bool last = false}) {
      final line = Row(children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: checked ? scheme.primary : null,
            border:
                checked ? null : Border.all(color: scheme.outline, width: 2),
          ),
          child: checked
              ? Icon(Icons.check_rounded, size: 13, color: scheme.onPrimary)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              if (qty.isNotEmpty)
                TextSpan(
                    text: '$qty ',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: item),
            ]),
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: checked ? TextDecoration.lineThrough : null,
              color: checked ? scheme.onSurfaceVariant : null,
            ),
          ),
        ),
        if (trailing != null)
          Text(trailing,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontSize: 11, color: scheme.onSurfaceVariant)),
        if (staple)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8)),
            child: Text('staple',
                style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10.5, color: scheme.onSurfaceVariant)),
          ),
      ]);
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: last
            ? null
            : BoxDecoration(
                border: Border(bottom: BorderSide(color: context.rb.separator))),
        child: staple ? Opacity(opacity: 0.55, child: line) : line,
      );
    }

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, navBarClearance(context)),
          children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grocery',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontSize: 22)),
                      Text('9 items · from 3 planned recipes',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.5,
                              color: scheme.onSurfaceVariant)),
                    ]),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle),
                child: Icon(Icons.ios_share_rounded,
                    size: 19, color: scheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 12),
            // Sync receipt banner — plan changes propagate WITH a receipt.
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                    scheme.secondaryContainer.withValues(alpha: 0.4),
                    scheme.surface),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.event_repeat_rounded,
                    size: 18, color: scheme.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                      'Salmon bumped to 4 servings — 3 amounts updated.',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontSize: 12.5, height: 1.4)),
                ),
                Icon(Icons.close_rounded,
                    size: 16, color: scheme.onSurfaceVariant),
              ]),
            ),
            const SizedBox(height: 12),
            // Merge prompt — suggest-and-confirm, never silent (§6.3).
            TokenCard(
              selected: true,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Same thing?',
                      style:
                          theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '2 lemons',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface)),
                      const TextSpan(text: ' (Pasta) + '),
                      TextSpan(
                          text: '4 lemons',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface)),
                      const TextSpan(text: ' (Salmon)'),
                    ]),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    FilledButton.tonal(
                        onPressed: () => _notWired(context, 'The grocery engine'),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14)),
                        child: const Text('Merge · 6 lemons')),
                    TextButton(
                        onPressed: () => _notWired(context, 'The grocery engine'),
                        child: const Text('Keep apart')),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Produce · 2'),
            const SizedBox(height: 8),
            TokenCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                row('6', 'lemons', trailing: '2 recipes'),
                row('400 g', 'spinach', checked: true, last: true),
              ]),
            ),
            const SizedBox(height: 14),
            SectionLabel(
              'Asian pantry · 1',
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.push_pin_rounded,
                      size: 12, color: scheme.primary),
                  const SizedBox(width: 3),
                  Text('your aisle',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          letterSpacing: 0.2,
                          color: scheme.primary)),
                ]),
              ),
            ),
            const SizedBox(height: 8),
            TokenCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                row('2 tbsp', 'sesame oil',
                    trailing: 'moved here by you', last: true),
              ]),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Pantry · 2'),
            const SizedBox(height: 8),
            TokenCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(children: [
                row('400 g', 'spaghetti'),
                row('', 'olive oil', staple: true, last: true),
              ]),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Staples stay quiet unless you tap them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.5, color: scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ),
      // The promoted shell bar, demo-wired: this preview is a pushed route,
      // so tabs and FAB only explain themselves.
      bottomNavigationBar: GlassNavBar(
        active: 1,
        onTab: (_) => _notWired(context, 'The shell nav'),
        onFab: () => _notWired(context, 'The shell nav'),
      ),
    );
  }
}

// ── 4d · Fair-use cap reached ───────────────────────────────────────────────

class CapReachedPreview extends StatelessWidget {
  const CapReachedPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerRight, child: _CloseCircle()),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(22)),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 32, color: scheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 14),
              Text("You've rescued a lot this year",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontSize: 26, height: 1.2)),
              const SizedBox(height: 8),
              Text(
                  "That's the fair-use cap we promised at purchase. It resets on 1 January.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant, height: 1.5)),
              const SizedBox(height: 16),
              TokenCard(
                radius: 16,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('2026 AI rescues',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontSize: 13)),
                        Text('600 / 600',
                            style: theme.textTheme.titleSmall?.copyWith(
                                fontSize: 13, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: 1,
                          minHeight: 8,
                          backgroundColor: scheme.surfaceContainerHigh),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        'Typing or pasting recipes in yourself is always unlimited — the cap only meters the AI.',
                        style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const Spacer(),
              if (kTopUpEnabled) ...[
                FilledButton(
                    onPressed: () => _notWired(context, 'The top-up pack'),
                    child: const Text('Add 1,200 rescues — \$5')),
                const SizedBox(height: 8),
              ],
              TextButton(
                  onPressed: () => _notWired(context, 'Manual entry'),
                  child: const Text('Type it in by hand')),
              const SizedBox(height: 6),
              Text('Everything you own keeps working, forever.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared preview scaffolding ──────────────────────────────────────────────

class _CloseCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: () => Navigator.of(context).maybePop(),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
        child:
            Icon(Icons.close_rounded, size: 19, color: scheme.onSurfaceVariant),
      ),
    );
  }
}

