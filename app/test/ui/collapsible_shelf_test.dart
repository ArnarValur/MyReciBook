// The shelf's one hard promise: a folded section builds NOTHING. The Pantry
// tab and the Add sheet both lean on it — the three starter packs are ~60
// products each, and the flat list they replace built all of them to draw a
// heading. If this test goes red, that cost is back.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:myrecibook/ui/widgets/collapsible_shelf.dart';

void main() {
  /// Counts builder calls per section so the test can assert on "never run",
  /// not merely on "not on screen" — offstage would still cost the build.
  Widget wrap({
    required Set<String> expanded,
    required Map<String, int> built,
    ValueChanged<String>? onToggle,
  }) =>
      MaterialApp(
        theme: rbLightTheme(),
        home: Scaffold(
          body: CollapsibleShelf(
            expanded: expanded,
            onToggle: onToggle ?? (_) {},
            sections: [
              for (final name in ['Dairy', 'Veggies'])
                ShelfSection(
                  id: name,
                  label: '· $name',
                  count: name == 'Dairy' ? 2 : 60,
                  starterPack: name == 'Veggies',
                  builder: (_) {
                    built[name] = (built[name] ?? 0) + 1;
                    return Text('$name body');
                  },
                ),
            ],
          ),
        ),
      );

  testWidgets('a collapsed section never calls its builder', (tester) async {
    final built = <String, int>{};
    await tester.pumpWidget(wrap(expanded: const {}, built: built));

    // Both headers are there, with their counts — a closed section still
    // says how much is behind it.
    expect(find.text('· Dairy'), findsOneWidget);
    expect(find.text('· Veggies'), findsOneWidget);
    expect(find.text('60'), findsOneWidget);
    // ...and neither body was ever built.
    expect(built, isEmpty);
    expect(find.text('Dairy body'), findsNothing);
  });

  testWidgets('only the open section builds; the folded one stays untouched',
      (tester) async {
    final built = <String, int>{};
    await tester.pumpWidget(wrap(expanded: const {'Dairy'}, built: built));

    expect(built['Dairy'], 1);
    expect(built.containsKey('Veggies'), isFalse);
    expect(find.text('Dairy body'), findsOneWidget);
    expect(find.text('Veggies body'), findsNothing);
  });

  testWidgets('tapping a header reports its id and nothing else',
      (tester) async {
    final built = <String, int>{};
    final tapped = <String>[];
    await tester.pumpWidget(
        wrap(expanded: const {}, built: built, onToggle: tapped.add));

    await tester.tap(find.text('· Veggies'));
    await tester.pump();

    expect(tapped, ['Veggies']);
    // The widget holds no state of its own: without the caller flipping the
    // set, the section is still folded and still unbuilt.
    expect(built, isEmpty);
  });

  testWidgets('an empty shelf draws no card at all', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: rbLightTheme(),
      home: const Scaffold(
        body: CollapsibleShelf(sections: [], expanded: {}, onToggle: _noop),
      ),
    ));

    expect(find.byType(SizedBox), findsWidgets);
    expect(find.byType(InkWell), findsNothing);
  });
}

void _noop(String _) {}
