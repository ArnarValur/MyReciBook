// The fair-use cap, reached — design 4d promoted from the debug gallery
// (2026-09-03). docs/ai-cap-mechanics.md §2: a user must never discover the
// cap through a failed extraction, so the import sheet sends them here
// BEFORE any AI door once the included grant is spent; the review screen
// lands here only as the backstop when a stale cached count let a call
// through. Free paths lead — "Type it in" first, the top-up second.
//
// Pops with [CapReachedResult.typeIt] when the user takes the free door;
// the caller opens manual entry itself (the sheet by popping ImportManual,
// the review screen by replacing itself).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features.dart';
import 'quota_model.dart';
import 'theme.dart';
import 'widgets/quota_counter_card.dart';

enum CapReachedResult { typeIt }

class CapReachedScreen extends StatelessWidget {
  const CapReachedScreen({super.key, this.used, this.cap});

  /// Gallery overrides — the preview has no spent allowance to show. Null
  /// reads the live numbers QuotaModel cached from the proxy's last answer.
  final int? used;
  final int? cap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final live = context.watch<QuotaModel?>()?.quota;
    final used = this.used ?? live?.used;
    final cap = this.cap ?? live?.cap;
    final grant = cap == null
        ? 'the rescues included with MyReciBook'
        : 'the ${formatRescues(cap)} included with MyReciBook';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  key: const Key('cap-close'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 19),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Icon(Icons.hourglass_top_rounded,
                      size: 32, color: scheme.onSecondaryContainer),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "You've used your included rescues",
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 26, height: 1.2),
              ),
              const SizedBox(height: 8),
              Text(
                "That's $grant. Nothing resets — type recipes in yourself, "
                'always free, or run on your own Gemini key.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              // The same card as Settings: the numbers that refused the
              // call, and the own-key door behind its cog.
              QuotaCounterCard(used: used, cap: cap),
              const SizedBox(height: 10),
              Text(
                'Typing or pasting recipes in yourself is always unlimited — '
                'the cap only meters the AI.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(height: 1.5, color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('cap-type-it'),
                onPressed: () =>
                    Navigator.of(context).pop(CapReachedResult.typeIt),
                child: const Text('Type it in — always free'),
              ),
              const SizedBox(height: 8),
              if (kTopUpEnabled)
                OutlinedButton(
                  key: const Key('cap-top-up'),
                  onPressed: null, // billing seam: wired with the IAP
                  child: const Text('Add 600 rescues — \$5'),
                )
              else
                Text(
                  'Top-up packs — 600 rescues for \$5, never expiring — '
                  'arrive with billing.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              const SizedBox(height: 6),
              Text(
                'Everything you own keeps working, forever.',
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
