// Cap-reached screen (4d promoted): the counter that refused the call, the
// free door first, and a close that leaves without a choice.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/ui/cap_reached_screen.dart';
import 'package:myrecibook/ui/theme.dart';

void main() {
  Future<Future<CapReachedResult?>> push(WidgetTester tester) async {
    late Future<CapReachedResult?> result;
    await tester.pumpWidget(MaterialApp(
      theme: rbLightTheme(),
      home: Builder(
        builder: (ctx) => TextButton(
          onPressed: () {
            result = Navigator.of(ctx).push<CapReachedResult>(
              MaterialPageRoute(
                builder: (_) => const CapReachedScreen(used: 1200, cap: 1200),
              ),
            );
          },
          child: const Text('go'),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('shows the full meter and pops with the free choice',
      (tester) async {
    final result = await push(tester);
    expect(find.text("You've used your included rescues"), findsOneWidget);
    expect(find.textContaining('the 1,200 included with MyReciBook'),
        findsOneWidget);
    expect(find.text('1,200 / 1,200'), findsOneWidget);
    expect(find.text('0 of 1,200 requests left.'), findsOneWidget);
    // Nothing anywhere may imply a reset (Decision 1) — said out loud.
    expect(find.textContaining('Nothing resets'), findsOneWidget);
    expect(find.textContaining('resets on'), findsNothing);

    await tester.tap(find.byKey(const Key('cap-type-it')));
    await tester.pumpAndSettle();
    expect(await result, CapReachedResult.typeIt);
  });

  testWidgets('close leaves with no choice', (tester) async {
    final result = await push(tester);
    await tester.tap(find.byKey(const Key('cap-close')));
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });
}
