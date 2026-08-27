// Screens 1c/1d of the first-run flow — Claude Design onboarding mockup.
//
// A slide is a stack of features: a cropped screenshot, a title, a line. Two
// per slide reads as a tour, one per slide reads as a headline — the mockup
// uses both, so [OnboardingSlide] carries a list and the tile height follows
// from how many it holds.
//
// The header says WHAT'S NEW IN <version>, which is the whole point of the
// versioned replay: bump kOnboardingVersion after a release and these become
// the release notes everybody actually sees. Skip, the corner X and the final
// button all exit the same way.
//
// SCREENSHOTS PENDING — Arnar is cropping them. Until [SlideFeature.image] is
// non-null the tile draws the mockup's hatch and says so.

import 'package:flutter/material.dart';

import '../theme.dart';
import '../../version.dart';
import 'onboarding_scaffold.dart';

class SlideFeature {
  const SlideFeature({required this.title, required this.body, this.image});

  final String title;
  final String body;

  /// Asset path of the cropped screenshot. Null until Arnar supplies it —
  /// add the file to pubspec assets and name it here, nothing else changes.
  final String? image;
}

class OnboardingSlide {
  const OnboardingSlide(this.features);

  final List<SlideFeature> features;
}

/// The tour for [kOnboardingVersion]. Rewrite this list when the version is
/// bumped: it IS the what's-new copy.
const List<OnboardingSlide> kSlides = [
  OnboardingSlide([
    SlideFeature(
      title: 'Rescue recipes from screenshots',
      body: 'Share one or many to MyReciBook — it reads them into plain '
          'files you own.',
    ),
    SlideFeature(
      title: 'Cook mode',
      body: 'Big steps, screen stays awake — made for messy hands.',
    ),
  ]),
  OnboardingSlide([
    SlideFeature(
      title: 'Grocery list from any recipe',
      body: 'One tap adds the ingredients — quantities merge across recipes.',
    ),
  ]),
];

class SlidesScreen extends StatefulWidget {
  const SlidesScreen({super.key, required this.onDone});

  /// Skip, the X and the final button all land here — one exit, marked once.
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "WHAT'S NEW IN $kAppVersion",
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.9,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant),
                    ),
                  ),
                  Material(
                    color: scheme.surfaceContainerHigh,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const Key('slides-close-button'),
                      customBorder: const CircleBorder(),
                      onTap: widget.onDone,
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(Icons.close_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: kSlides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) => _Slide(slide: kSlides[i]),
                ),
              ),
              // Mid-flow: Skip on the left, dots centred. Final slide: dots
              // centred over the one button that ends it.
              if (!_last)
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const Key('slides-skip-button'),
                          onPressed: widget.onDone,
                          child: Text('Skip',
                              style: theme.textTheme.labelLarge?.copyWith(
                                  color: scheme.onSurfaceVariant)),
                        ),
                      ),
                    ),
                    _Dots(count: kSlides.length, index: _index),
                    const Spacer(),
                  ],
                )
              else ...[
                _Dots(count: kSlides.length, index: _index),
                const SizedBox(height: 14),
                GradientButton(
                  key: const Key('slides-next-button'),
                  label: 'Start cooking',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == index
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.8),
            ),
          ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    // One feature gets the tall tile (1d), two share the height (1c).
    final tall = slide.features.length == 1;
    // Scrolls rather than clips: a short screen or a large system font must
    // move the content, never cut a caption off.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          for (final f in slide.features) ...[
            if (f.image == null)
              OnboardingSlot(
                  label: 'cropped screenshot',
                  note: f.title.toLowerCase(),
                  height: tall ? 420 : 220)
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(f.image!,
                    height: tall ? 420 : 220, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            Text(f.title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(f.body,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.5,
                    height: 1.5,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}
