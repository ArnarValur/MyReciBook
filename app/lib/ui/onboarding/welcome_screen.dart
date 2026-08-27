// Screen 1a of the first-run flow — built from the Claude Design onboarding
// mockup (docs/MyReciBook Flutter welcome-mockups.zip, turn 1, option 1a).
//
// The mark, the wordmark, the two-line promise, the paragraph, one full-width
// button, and the reassurance line under it. Copy is the mockup's verbatim:
// it is the pitch, and rewriting it here would fork it from the landing page.

import 'package:flutter/material.dart';

import '../brand_mark.dart';
import '../theme.dart';
import 'onboarding_scaffold.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onContinue});

  /// Straight to setup. No skip: there is no app to skip into until a folder
  /// exists.
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Centred when it fits, scrolls when it does not (small screens,
              // large system fonts) — never clipped.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          BrandMark(
                            size: 92,
                            background: scheme.primaryContainer,
                            foreground: scheme.onPrimary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'MyReciBook',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.44,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Pay once.\nCook forever.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontSize: 31,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.465,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 270),
                            child: Text(
                              'No subscription. No account. Ever. Your recipes '
                              'are plain files on this phone — if MyReciBook '
                              'vanished tomorrow, they wouldn’t. Unless '
                              'you dropped your phone into a volcano and did '
                              'not use your cloud storage, then it’s a '
                              'oopsie.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                  height: 1.6,
                                  color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              GradientButton(
                key: const Key('welcome-continue-button'),
                label: 'Set up my recipe box',
                icon: Icons.arrow_forward_rounded,
                onPressed: onContinue,
              ),
              const SizedBox(height: 10),
              Text(
                'about a minute · everything can change later',
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
