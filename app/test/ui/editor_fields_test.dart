// Editor field widgets: the stepper clamps and never emits outside 1–99,
// the duration pill does minutes/hours math and mirrors the file's raw
// shape, and the cover slot renders both states and routes camera/gallery
// picks through PhotoSources without touching the cover on back-out.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myrecibook/ui/photo_sources.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:myrecibook/ui/widgets/editor_fields.dart';
import 'package:provider/provider.dart';

void main() {
  Widget wrap(Widget child, {PhotoSources? photos}) {
    final page = Scaffold(
      body: Center(child: SizedBox(width: 240, child: child)),
    );
    return MaterialApp(
      theme: rbLightTheme(),
      home: photos == null
          ? page
          : Provider<PhotoSources>.value(value: photos, child: page),
    );
  }

  group('ServingsStepper', () {
    testWidgets('renders the label, steps both ways, clamps at 1 and 99',
        (tester) async {
      var value = 2;
      final log = <int>[];
      await tester.pumpWidget(wrap(StatefulBuilder(
        builder: (context, setState) => ServingsStepper(
          value: value,
          onChanged: (v) {
            log.add(v);
            setState(() => value = v);
          },
        ),
      )));

      expect(find.text('2 servings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('servings-plus')));
      await tester.pump();
      expect(find.text('3 servings'), findsOneWidget);

      await tester.tap(find.byKey(const Key('servings-minus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('servings-minus')));
      await tester.pump();
      expect(find.text('1 serving'), findsOneWidget); // singular at 1

      // Lower clamp: minus at 1 emits nothing.
      await tester.tap(find.byKey(const Key('servings-minus')));
      await tester.pump();
      expect(find.text('1 serving'), findsOneWidget);
      expect(log, [3, 2, 1]);

      // Upper clamp: plus at 99 emits nothing.
      log.clear();
      value = 99;
      await tester.pumpWidget(wrap(ServingsStepper(
        value: value,
        onChanged: log.add,
      )));
      expect(find.text('99 servings'), findsOneWidget);
      await tester.tap(find.byKey(const Key('servings-plus')));
      await tester.pump();
      expect(log, isEmpty);
      await tester.tap(find.byKey(const Key('servings-minus')));
      await tester.pump();
      expect(log, [98]);
    });

    test('servingsOf fills amount and the displayed raw', () {
      final one = ServingsStepper.servingsOf(1);
      expect(one.amount, 1);
      expect(one.raw, '1 serving');
      final four = ServingsStepper.servingsOf(4);
      expect(four.amount, 4);
      expect(four.raw, '4 servings');
    });
  });

  group('DurationField', () {
    testWidgets('typed minutes, unit flip to hours, comma decimals, clearing',
        (tester) async {
      int? out = -1;
      await tester.pumpWidget(wrap(DurationField(onChanged: (m) => out = m)));

      await tester.enterText(find.byKey(const Key('duration-value')), '45');
      expect(out, 45);

      // Flip to hours: the number stays, the meaning changes.
      await tester.tap(find.byKey(const Key('duration-unit-hr')));
      await tester.pump();
      expect(out, 45 * 60);

      await tester.enterText(find.byKey(const Key('duration-value')), '1,5');
      expect(out, 90);

      await tester.tap(find.byKey(const Key('duration-unit-min')));
      await tester.pump();
      expect(out, 2); // 1.5 min rounds to 2

      await tester.enterText(find.byKey(const Key('duration-value')), '');
      expect(out, isNull);
    });

    testWidgets('initialMinutes prefills — whole hours as hr, else minutes',
        (tester) async {
      int? out;
      await tester.pumpWidget(wrap(DurationField(
          key: const Key('hours'),
          initialMinutes: 120,
          onChanged: (m) => out = m)));
      expect(find.text('2'), findsOneWidget);
      // hr must be the active unit: typing 3 means 3 hours.
      await tester.enterText(find.byKey(const Key('duration-value')), '3');
      expect(out, 180);

      // Fresh key → fresh State, so the prefill logic runs again.
      await tester.pumpWidget(wrap(DurationField(
          key: const Key('minutes'),
          initialMinutes: 90,
          onChanged: (m) => out = m)));
      expect(find.text('90'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('duration-value')), '30');
      expect(out, 30);
    });

    test('totalMinutesOf math', () {
      expect(DurationField.totalMinutesOf('25', DurationUnit.minutes), 25);
      expect(DurationField.totalMinutesOf(' 2 ', DurationUnit.hours), 120);
      expect(DurationField.totalMinutesOf('1,5', DurationUnit.hours), 90);
      expect(DurationField.totalMinutesOf('1.5', DurationUnit.hours), 90);
      expect(DurationField.totalMinutesOf('', DurationUnit.minutes), isNull);
      expect(DurationField.totalMinutesOf('abc', DurationUnit.minutes), isNull);
      expect(DurationField.totalMinutesOf('0', DurationUnit.minutes), isNull);
    });

    test('rawOf and timesOf mirror the stored shape', () {
      expect(DurationField.rawOf(25), '25 min');
      expect(DurationField.rawOf(60), '1 hr');
      expect(DurationField.rawOf(90), '1 hr 30 min');
      expect(DurationField.rawOf(0), isNull);
      expect(DurationField.rawOf(null), isNull);

      final t = DurationField.timesOf(90)!;
      expect(t.totalMin, 90);
      expect(t.raw, '1 hr 30 min');
      expect(t.toJson(),
          {'prep_min': null, 'cook_min': null, 'total_min': 90, 'raw': '1 hr 30 min'});
      expect(DurationField.timesOf(null), isNull);
      expect(DurationField.timesOf(0), isNull);
    });
  });

  group('CoverPickerField', () {
    late Directory tmp;
    late File photo;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('myrecibook_editor_fields');
      photo = File('${tmp.path}/pick.png')
        ..writeAsBytesSync(img.encodePng(img.Image(width: 4, height: 4)));
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    testWidgets('empty slot → sheet offers camera + gallery → gallery pick',
        (tester) async {
      File? picked;
      var changes = 0;
      final photos = PhotoSources(
          gallery: () async => [photo], camera: () async => [photo]);
      await tester.pumpWidget(wrap(
        CoverPickerField(
          file: null,
          onChanged: (f) {
            picked = f;
            changes++;
          },
        ),
        photos: photos,
      ));

      expect(find.text('Add a cover photo'), findsOneWidget);
      expect(find.byType(Image), findsNothing);

      await tester.tap(find.byKey(const Key('cover-field')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cover-field-camera')), findsOneWidget);
      expect(find.byKey(const Key('cover-field-gallery')), findsOneWidget);
      // No photo yet — nothing to remove.
      expect(find.byKey(const Key('cover-field-remove')), findsNothing);

      await tester.tap(find.byKey(const Key('cover-field-gallery')));
      await tester.pumpAndSettle();
      expect(picked, photo);
      expect(changes, 1);
    });

    testWidgets('no camera → no camera tile; backing out changes nothing',
        (tester) async {
      var changes = 0;
      // Gallery returns empty = user backed out of the system picker.
      final photos = PhotoSources(gallery: () async => const [], camera: null);
      await tester.pumpWidget(wrap(
        CoverPickerField(file: null, onChanged: (_) => changes++),
        photos: photos,
      ));

      await tester.tap(find.byKey(const Key('cover-field')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cover-field-camera')), findsNothing);
      expect(find.byKey(const Key('cover-field-gallery')), findsOneWidget);

      await tester.tap(find.byKey(const Key('cover-field-gallery')));
      await tester.pumpAndSettle();
      expect(changes, 0); // back-out must leave the cover alone
    });

    testWidgets('picked state renders the image and remove emits null',
        (tester) async {
      File? current = photo;
      var removed = false;
      final photos = PhotoSources(gallery: () async => [photo]);
      await tester.pumpWidget(wrap(
        CoverPickerField(
          file: current,
          onChanged: (f) {
            current = f;
            removed = f == null;
          },
        ),
        photos: photos,
      ));

      expect(find.text('Add a cover photo'), findsNothing);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('change'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cover-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cover-field-remove')));
      await tester.pumpAndSettle();
      expect(removed, isTrue);
      expect(current, isNull);
    });
  });
}
