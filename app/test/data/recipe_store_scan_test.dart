// The folder scan versus the files the app itself writes. tags.json lives
// beside the recipes by design, and the scan used to count it as "1 files in
// the folder couldn't be read" — a permanent false alarm about our own file
// (Arnar 2026-08-27). These pin that app-owned files are neither read as
// recipes nor counted, while genuinely foreign or broken files still are.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tmp;
  late LocalFolderStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_scan_test');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
  });

  tearDown(() async => tmp.delete(recursive: true));

  test('tags.json beside the recipes is not a skipped file', () async {
    await store.save(cannedRecipe('a', 'Soup'), const []);
    await File('${tmp.path}/recipes/tags.json')
        .writeAsString('{"version":1,"tags":[{"name":"Weeknight"}]}');

    final result = await store.listAll();
    expect(result.recipes.map((r) => r.title), ['Soup']);
    expect(result.skipped, 0, reason: 'our own file is not a problem');
  });

  test('a foreign or broken file still counts, once, without failing the scan',
      () async {
    await store.save(cannedRecipe('a', 'Soup'), const []);
    await File('${tmp.path}/recipes/notes.json')
        .writeAsString('{"someone":"elses"}');
    await File('${tmp.path}/recipes/broken.json').writeAsString('{nope');

    final result = await store.listAll();
    expect(result.recipes.map((r) => r.title), ['Soup']);
    expect(result.skipped, 2);
  });
}
