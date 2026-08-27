// The tag editor page at the widget level. The blank-editor regression is
// why this file exists: a Center inside bottomNavigationBar took the whole
// height the Scaffold offered, the body got none, and a release build
// shipped an empty New tag screen (Arnar 2026-08-28). A zero-height body
// builds none of the ListView's children, so the first test fails on any
// layout that squeezes the form away again.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/tag_editor_screen.dart';
import 'package:myrecibook/ui/tags_model.dart';
import 'package:provider/provider.dart';

void main() {
  late Directory tmp;
  late TagsModel model;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_editor_test');
    final store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    model = TagsModel(store: MemoryTagStore(), library: LibraryModel(store));
    await model.load();
  });

  tearDown(() async => tmp.delete(recursive: true));

  Widget wrap(Widget child) => ChangeNotifierProvider<TagsModel>.value(
      value: model, child: MaterialApp(home: child));

  testWidgets('the whole form is on screen, not just the save button',
      (tester) async {
    await tester.pumpWidget(wrap(const TagEditorScreen()));

    expect(find.byKey(const Key('tag-name-field')), findsOneWidget);
    expect(find.byKey(const Key('tag-show-label-switch')), findsOneWidget);
    expect(find.text('COLOUR'), findsOneWidget);
    expect(find.text('ICON'), findsOneWidget);
    expect(find.text('DISHES'), findsOneWidget,
        reason: 'the icon grid actually built its groups');
    expect(find.byKey(const Key('tag-save-button')), findsOneWidget);
  });

  testWidgets('creating a tag saves it and hands the name back', (tester) async {
    String? returned;
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => returned = await showTagEditor(context),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('tag-name-field')), 'Weeknight');
    await tester.tap(find.byKey(const Key('tag-save-button')));
    await tester.pumpAndSettle();

    expect(model.tags.single.name, 'Weeknight');
    expect(returned, 'Weeknight',
        reason: 'the picker sheet relies on the name coming back');
  });

  testWidgets('saving without a name refuses instead of writing', (tester) async {
    await tester.pumpWidget(wrap(const TagEditorScreen()));
    await tester.tap(find.byKey(const Key('tag-save-button')));
    await tester.pump();

    expect(model.tags, isEmpty);
    expect(find.text('Give it a name'), findsOneWidget);
  });
}
