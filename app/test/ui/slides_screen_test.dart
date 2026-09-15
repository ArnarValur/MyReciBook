// The welcome slides carry real screenshots: every feature names an asset,
// the asset is in the bundle, and the placeholder hatch never shows.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/ui/onboarding/onboarding_scaffold.dart';
import 'package:myrecibook/ui/onboarding/slides_screen.dart';
import 'package:myrecibook/ui/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every slide feature names an asset that exists in the bundle',
      () async {
    for (final slide in kSlides) {
      for (final f in slide.features) {
        for (final b in Brightness.values) {
          final path = f.imageFor(b);
          expect(path, isNotNull, reason: '${f.title} has no $b screenshot');
          final bytes = await rootBundle.load(path!);
          expect(bytes.lengthInBytes, greaterThan(1000),
              reason: '$path is empty');
        }
      }
    }
  });

  testWidgets('slides draw the screenshots, never the placeholder',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: rbDarkTheme(),
      home: SlidesScreen(onDone: () {}),
    ));
    await tester.pump();
    for (var i = 0; i < kSlides.length; i++) {
      expect(find.byType(OnboardingSlot), findsNothing);
      expect(find.byType(Image), findsNWidgets(kSlides[i].features.length));
      if (i < kSlides.length - 1) {
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 800);
        await tester.pumpAndSettle();
      }
    }
  });
}
