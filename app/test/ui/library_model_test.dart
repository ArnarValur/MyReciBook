// LibraryModel failure routing: transient SAF_IO must never strand the
// loading spinner or skip the rescan, and GrantLost during a save must NOT
// swap the gate — that would unmount the review/detail screen mid-edit.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/data/saf_store.dart';
import 'package:myrecibook/domain/recipe.dart';
import 'package:myrecibook/ui/library_model.dart';

Recipe recipe(String id) => Recipe(
      schemaVersion: 1,
      id: id,
      title: 'Recipe $id',
      source: const RecipeSource(type: 'screenshot'),
      ingredients: const [Ingredient(raw: '2 eggs')],
      steps: const [RecipeStep(raw: 'Mix and fry.')],
    );

class StubStore implements RecipeStore {
  List<Recipe> recipes = const [];
  Object? listError;
  Object? deleteError;
  Object? saveError;
  int listCalls = 0;

  @override
  Future<StoreResult> listAll() async {
    listCalls++;
    if (listError != null) throw listError!;
    return StoreResult(recipes, 0);
  }

  @override
  Future<Recipe?> load(String id) async => null;

  @override
  Future<Recipe> save(Recipe recipe, List<File> cachedImages,
      {File? coverImage}) async {
    if (saveError != null) throw saveError!;
    return recipe;
  }

  @override
  Future<void> delete(String id) async {
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<File?> imageFile(String ref) async => null;
}

void main() {
  late StubStore store;
  late int grantLostCalls;
  late LibraryModel model;

  setUp(() {
    store = StubStore();
    grantLostCalls = 0;
    model = LibraryModel(store, onGrantLost: () => grantLostCalls++);
  });

  test('SAF_IO during rescan: spinner cleared, last good list kept', () async {
    store.recipes = [recipe('r1')];
    await model.rescan();
    expect(model.recipes.map((r) => r.id), ['r1']);

    store.listError = PlatformException(code: 'SAF_IO', message: 'hiccup');
    await model.rescan(); // must not throw out of the un-awaited call site

    expect(model.loading, isFalse);
    expect(model.recipes.map((r) => r.id), ['r1']);
    expect(grantLostCalls, 0);
  });

  test('grant lost during rescan: spinner cleared, gate callback fired',
      () async {
    store.listError = GrantLostException();
    await model.rescan();
    expect(model.loading, isFalse);
    expect(grantLostCalls, 1);
  });

  test('SAF_IO during delete: no throw, rescan still runs', () async {
    store.deleteError = PlatformException(code: 'SAF_IO', message: 'hiccup');
    await model.delete('r1');
    expect(store.listCalls, 1);
    expect(model.loading, isFalse);
    expect(grantLostCalls, 0);
  });

  test('grant lost during save propagates without swapping the gate',
      () async {
    store.saveError = GrantLostException();
    await expectLater(model.saveImported(recipe('r1'), const []),
        throwsA(isA<GrantLostException>()));
    expect(grantLostCalls, 0); // review stays mounted; edits survive
  });
}
