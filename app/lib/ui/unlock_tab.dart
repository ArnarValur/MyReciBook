// Unlock tab — nav slot 2 since 2026-08-15 (Arnar: the queue tab was dead
// weight; this slot sells the app instead). The pitch is hi-fi 3g promoted
// from the debug gallery: same copy, same ONE-TIME tertiary moment, same
// cap-in-writing line (constraint 2 — the cap is stated where the money is).
//
// Engine honesty: Google Play billing does not exist until billing 3g (Play
// fee → Console app → one-time product), so the CTA is disabled and says
// why — the "awaiting keys" pattern, never a button that silently no-ops.
// Restore-purchase arrives WITH billing; showing it earlier would be a
// dead end. Spread-the-word rows wait behind [kSpreadWordEnabled] for a
// live destination.
//
// $25 is the price (Arnar, 2026-08-31). 1,200 rescues come with it.

import 'package:flutter/material.dart';

import '../features.dart';
import 'theme.dart';
import 'widgets/skin.dart';

/// One-time price — single source for the card and the CTA label.
const String kUnlockPrice = '\$25';

/// The 3g pitch: headline, price card, why-not-a-subscription card.
/// Shared by [UnlockTab] and the DevGallery's PaywallPreview so the copy
/// can never drift between the tab and the future hard-paywall route.
class PaywallPitch extends StatelessWidget {
  const PaywallPitch({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    Widget check(String text) => Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_rounded, size: 18, color: scheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: 34,
              color: scheme.onSecondaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Pay once.\nCook forever.',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontSize: 29,
            height: 1.15,
            letterSpacing: -0.58,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No subscription. No account. Ever.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        TokenCard(
          radius: 16,
          selected: true,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    kUnlockPrice,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // The app's ONE tertiary moment — the commerce accent.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ONE-TIME',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              check('Every recipe, forever, in your storage'),
              // The top-up quantity on the same card as the cap (Decision 1,
              // 2026-09-01 + framing rule 1: disclosed before purchase).
              check('1,200 AI recipe rescues included — '
                  'top up 600 for \$5 if they ever run out'),
              check('A grocery list that actually merges'),
              check('All future features included'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TokenCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why not a subscription?',
                style: theme.textTheme.titleSmall?.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 7),
              Text(
                "Because your recipe box shouldn't have a landlord. You "
                'buy MyReciBook like you\'d buy a good knife: once.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12.5,
                  height: 1.55,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Nav slot 2. Scrolls under the glass bar like every tab surface.
class UnlockTab extends StatelessWidget {
  const UnlockTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    return Scaffold(
      body: SafeArea(
        bottom: false, // content scrolls under the shell's glass bar
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, navBarClearance(context)),
          children: [
            const PaywallPitch(),
            const SizedBox(height: 20),
            // Billing 3g replaces these two with the real purchase flow +
            // restore-purchase line. Until then the button says why it waits.
            FilledButton(
              onPressed: null,
              child: Text('Unlock MyReciBook — $kUnlockPrice'),
            ),
            const SizedBox(height: 10),
            Text(
              'Google Play billing connects when MyReciBook reaches the '
              'store — nothing to buy just yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (kSpreadWordEnabled) ...[
              const SizedBox(height: 24),
              const SectionLabel('Spread the word'),
              const SizedBox(height: 8),
              _SpreadRow(
                icon: Icons.star_rounded,
                title: 'Rate MyReciBook',
                caption: 'A review on Google Play helps other cooks find it',
                onTap: () => _notWired(context, 'Rating'),
              ),
              _SpreadRow(
                icon: Icons.ios_share_rounded,
                title: 'Share with a friend',
                caption: 'Someone you know has a camera roll full of recipes',
                onTap: () => _notWired(context, 'Sharing'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void _notWired(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$what lands with the store listing — not long now.'),
      ),
    );
  }
}

class _SpreadRow extends StatelessWidget {
  const _SpreadRow({
    required this.icon,
    required this.title,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TokenCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 21, color: scheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
