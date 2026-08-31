// Unlock tab (nav slot 2 since 2026-08-15) — the 3g pitch as a live surface.
// Guards the product constraints that must survive implementation: pay-once
// framing, the cap stated in writing next to the price (constraint 2), and
// engine honesty (a CTA that says why it waits instead of no-opping).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:myrecibook/ui/unlock_tab.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool dark = false}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: dark ? rbDarkTheme() : rbLightTheme(),
          home: const UnlockTab(),
        ),
      );

  testWidgets('pitch carries the 3g promises, in both themes', (tester) async {
    for (final dark in [false, true]) {
      await pump(tester, dark: dark);
      expect(find.text('Pay once.\nCook forever.'), findsOneWidget);
      expect(find.text('No subscription. No account. Ever.'), findsOneWidget);
      expect(find.text(kUnlockPrice), findsOneWidget);
      expect(find.text('ONE-TIME'), findsOneWidget);
      // Constraint 2: the rescue count stated next to the price.
      expect(
        find.text('1,200 AI recipe rescues included'),
        findsOneWidget,
      );
      expect(
        find.text('Every recipe, forever, in your storage'),
        findsOneWidget,
      );
    }
  });

  // Static card since 2026-08-17 (Arnar, on the installed build: no
  // practical reason for a one-paragraph collapse).
  testWidgets('why-not-a-subscription copy is always visible', (tester) async {
    await pump(tester);
    expect(find.text('Why not a subscription?'), findsOneWidget);
    expect(
      find.textContaining('recipe box shouldn\'t have a landlord'),
      findsOneWidget,
    );
  });

  testWidgets('CTA waits for billing 3g honestly; no dead spread rows', (
    tester,
  ) async {
    await pump(tester);

    final cta = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Unlock MyReciBook — $kUnlockPrice'),
    );
    expect(cta.onPressed, isNull);
    expect(find.textContaining('nothing to buy just yet'), findsOneWidget);

    // No restore-purchase promise before an engine exists, and the
    // spread-the-word rows wait behind kSpreadWordEnabled for a live
    // destination (dead-end rule).
    expect(find.textContaining('Restore purchase'), findsNothing);
    expect(find.text('Rate MyReciBook'), findsNothing);
    expect(find.text('Share with a friend'), findsNothing);
  });
}
