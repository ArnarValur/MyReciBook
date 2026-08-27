// TagsModel: the two operations that reach into the recipe files.
//
// Rename and delete are the whole risk in this track — everything else only
// touches tags.json, which is disposable by design. These pin that a rename
// rewrites every recipe carrying the old name, that delete really deletes
// (Arnar 2026-08-27), and that the recipe files stay the truth about which
// tags exist even when the decorations are gone.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/domain/recipe_tag.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/tags_model.dart';

import '../helpers/fixtures.dart';

void main() {
  late Directory tmp;
  late LocalFolderStore store;
  late LibraryModel library;
  late TagsModel model;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_tags_test');
    store = LocalFolderStore(Directory('${tmp.path}/recipes'));
    library = LibraryModel(store);
    model = TagsModel(store: MemoryTagStore(), library: library);
    await model.load();
  });

  tearDown(() async => tmp.delete(recursive: true));

  Future<void> seed(String id, String title, List<String> tags) async {
    await store.save(cannedRecipe(id, title).copyWith(tags: tags), const []);
  }

  test('a tag string with no decoration is still a tag', () async {
    await seed('a', 'Soup', ['Weeknight']);
    await library.rescan();

    // Nothing in tags.json, but the library knows the name — so the app must.
    expect(model.tags, isEmpty);
    expect(model.undecoratedNames, ['Weeknight']);
    expect(model.usageOf('Weeknight'), 1);
    // And it draws, plain.
    final chip = model.chipFor('Weeknight');
    expect(chip.name, 'Weeknight');
    expect(chip.icon, isNull);
    expect(chip.showLabel, isTrue);
  });

  test('two tags cannot share a name, whatever the casing', () async {
    expect(await model.create(RecipeTag(name: 'Weeknight')), isTrue);
    expect(await model.create(RecipeTag(name: ' weeknight ')), isFalse);
    expect(await model.create(RecipeTag(name: '  ')), isFalse);
    expect(model.tags.length, 1);
  });

  test('renaming rewrites every recipe that carried the old name', () async {
    await seed('a', 'Soup', ['Weeknight', 'Cheap']);
    await seed('b', 'Stew', ['Weeknight']);
    await seed('c', 'Cake', ['Sweet']);
    await library.rescan();
    await model.create(RecipeTag(name: 'Weeknight', icon: 'quick'));

    final ok = await model.update(
        'Weeknight', RecipeTag(name: 'School night', icon: 'quick'));
    expect(ok, isTrue);

    await library.rescan();
    Set<String> tagsOf(String id) =>
        library.recipes.firstWhere((r) => r.id == id).tags.toSet();
    expect(tagsOf('a'), {'School night', 'Cheap'});
    expect(tagsOf('b'), {'School night'});
    expect(tagsOf('c'), {'Sweet'}, reason: 'untouched recipes stay untouched');
    expect(model.tags.single.name, 'School night');
    expect(model.tags.single.icon, 'quick', reason: 'the outfit survives');
  });

  test('changing only the icon touches no recipe file', () async {
    await seed('a', 'Soup', ['Weeknight']);
    await library.rescan();
    await model.create(RecipeTag(name: 'Weeknight'));
    final before =
        await File('${tmp.path}/recipes/a.json').lastModified();

    await model.update('Weeknight',
        RecipeTag(name: 'Weeknight', icon: '🥑', color: TagColor.green));

    expect(await File('${tmp.path}/recipes/a.json').lastModified(), before);
    expect(model.tags.single.isEmojiIcon, isTrue);
  });

  test('deleting strips the name from the recipes too', () async {
    await seed('a', 'Soup', ['Weeknight', 'Cheap']);
    await seed('b', 'Stew', ['Weeknight']);
    await library.rescan();
    await model.create(RecipeTag(name: 'Weeknight'));

    await model.delete('Weeknight');
    await library.rescan();

    expect(library.recipes.firstWhere((r) => r.id == 'a').tags, ['Cheap']);
    expect(library.recipes.firstWhere((r) => r.id == 'b').tags, isEmpty);
    expect(model.tags, isEmpty);
    // Gone means gone: no ghost left for the filter row to offer.
    expect(model.undecoratedNames, ['Cheap']);
  });

  test('a tag that arrived with an import can be deleted without adopting it',
      () async {
    // Link import maps recipeCategory/recipeCuisine/keywords into tags, so a
    // rescued recipe turns up carrying names nobody invented. Deleting one
    // must not require creating it first (Arnar 2026-08-27).
    await seed('a', 'Burritos', ['American', 'breakfast']);
    await seed('b', 'Dip', ['American']);
    await library.rescan();
    expect(model.tags, isEmpty, reason: 'nothing decorated — that is the case');
    expect(model.undecoratedNames, ['American', 'breakfast']);

    await model.delete('American');
    await library.rescan();

    expect(library.recipes.firstWhere((r) => r.id == 'a').tags, ['breakfast']);
    expect(library.recipes.firstWhere((r) => r.id == 'b').tags, isEmpty);
    expect(model.undecoratedNames, ['breakfast']);
  });

  test('renaming onto a name that already exists is refused', () async {
    await model.create(RecipeTag(name: 'Weeknight'));
    await model.create(RecipeTag(name: 'Sunday'));
    expect(await model.update('Weeknight', RecipeTag(name: 'sunday')), isFalse);
    expect(model.tags.map((t) => t.name), ['Weeknight', 'Sunday']);
  });

  test('toggling a tag on a recipe adds then removes it', () async {
    await seed('a', 'Soup', const []);
    await library.rescan();
    final recipe = library.recipes.single;

    final on = await model.toggleOn(recipe, 'Weeknight');
    expect(on.tags, ['Weeknight']);
    final off = await model.toggleOn(on, 'weeknight');
    expect(off.tags, isEmpty, reason: 'casing must not create a second tag');
  });

  test('order is the filter row order, and it survives a save', () async {
    await model.create(RecipeTag(name: 'One'));
    await model.create(RecipeTag(name: 'Two'));
    await model.create(RecipeTag(name: 'Three'));

    await model.reorder(2, 0); // Three to the front
    expect(model.tags.map((t) => t.name), ['Three', 'One', 'Two']);

    final reloaded = TagsModel(store: model.store, library: library);
    await reloaded.load();
    expect(reloaded.tags.map((t) => t.name), ['Three', 'One', 'Two']);
  });
}
