// Screen 3 of the first-run flow: a short swipe-through of what the app does.
//
// PLACEHOLDER CONTENT, 2026-08-27. Arnar's shape: each slide carries two rows
// of small cropped screenshots with a short line under each, then Done. He is
// supplying the crops and the copy; [kSlides] below is where they go, and
// every card until then is an [OnboardingSlot] that says it is empty.
//
// Skip and the corner X do the same thing — leave now — and both mark the
// flow seen, so a returning user who bumped into a replay is not asked twice.

import 'package:flutter/material.dart';

import '../theme.dart';
import 'onboarding_scaffold.dart';

/// One slide: a heading and four caption slots, laid out two per row.
/// Replace [captions] with Arnar's lines and give each an image when the crops
/// land — the slot count per slide is whatever this list holds.
class OnboardingSlide {
  const OnboardingSlide({required this.title, required this.captions});

  final String title;
  final List<String> captions;
}

/// Content pending. Three slides so the shape and the dots are real to walk
/// through; the words are stand-ins and read as stand-ins on purpose.
const List<OnboardingSlide> kSlides = [
  OnboardingSlide(
    title: 'Rescue what you already saved',
    captions: ['Screenshot', 'Photo of a page', 'A link', 'Type it yourself'],
  ),
  OnboardingSlide(
    title: 'Cook from it',
    captions: ['Your cookbook', 'Cook mode', 'Units your way', 'Share as PDF'],
  ),
  OnboardingSlide(
    title: 'Keep track',
    captions: ['Pantry', 'Grocery list', 'Meal diary', 'Nutrition'],
  ),
];

class SlidesScreen extends StatefulWidget {
  const SlidesScreen({super.key, required this.onDone});

  /// Skip, the X, and Done all land here. One exit, one place that marks the
  /// flow seen.
  final VoidCallback onDone;

  @override
  State<SlidesScreen> createState() => _SlidesScreenState();
}

class _SlidesScreenState extends State<SlidesScreen> {
  final _pages = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _last => _index == kSlides.length - 1;

  void _next() {
    if (_last) {
      widget.onDone();
      return;
    }
    _pages.nextPage(
        duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 0),
                child: IconButton(
                  key: const Key('slides-close-button'),
                  tooltip: 'Skip',
                  onPressed: widget.onDone,
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: kSlides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _Slide(slide: kSlides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < kSlides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i == _index
                            ? scheme.primary
                            : scheme.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    child: TextButton(
                      key: const Key('slides-skip-button'),
                      onPressed: _last ? null : widget.onDone,
                      child: Text('Skip',
                          style: theme.textTheme.labelLarge?.copyWith(
                              color: _last
                                  ? Colors.transparent
                                  : scheme.onSurfaceVariant)),
                    ),
                  ),
                  Expanded(
                    child: GradientButton(
                      key: const Key('slides-next-button'),
                      label: _last ? 'Start cooking' : 'Next',
                      icon: _last ? null : Icons.arrow_forward_rounded,
                      onPressed: _next,
                    ),
                  ),
                  const SizedBox(width: 96),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrolls rather than overflows: the crops are a fixed height, so a short
    // screen or a large system font must move the content, not clip it.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(slide.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontSize: 22, height: 1.25)),
          const SizedBox(height: 20),
          // Two per row — Arnar's "two rows of small cropped screenshots with
          // short text underneath each".
          for (var i = 0; i < slide.captions.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = i; j < i + 2 && j < slide.captions.length; j++)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: j == i ? 0 : 7, right: 7),
                        child: OnboardingSlot(
                            label: slide.captions[j],
                            note: 'screenshot pending',
                            height: 150),
                      ),
                    ),
                  // Keeps a lone tile at half width instead of stretching it.
                  if (slide.captions.length - i == 1) const Spacer(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
