// Screen 1 of the first-run flow. PLACEHOLDER — Arnar is designing this one
// (2026-08-27); the art, the words and the shape are all his. What is here is
// scaffolding: the brand surface, a hero slot sized like the real thing, and
// the one action that moves the flow on.
//
// Nothing in the empty slot pretends to be a design. When his art lands, the
// slot is where it goes and this comment goes away.

import 'package:flutter/material.dart';

import '../theme.dart';
import 'onboarding_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  /// Straight to the setup screen. No skip here: the flow cannot be skipped
  /// before a folder exists, because there is no app to skip into.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Centred when it fits, scrolls when it does not (small
              // screens, large system fonts) — never clipped.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const OnboardingSlot(
                            key: Key('welcome-art-slot'),
                            label: 'Welcome art',
                            note: 'Design pending — Arnar',
                            height: 240,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'MyReciBook',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontSize: 22, height: 1.25),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Collect the recipes buried in your camera roll.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              GradientButton(
                key: const Key('welcome-continue-button'),
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
