// LocalDiaryStore against real temp dirs. The contracts: an empty day leaves
// NO file, a corrupt file reads as an empty day instead of taking the screen
// down (§7), and a hostile stem never escapes the diary folder.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/diary_store.dart';
import 'package:myrecibook/domain/diary.dart';
import 'package:myrecibook/domain/product.dart';

DiaryEntry entry(String id, {double kcal = 100, String name = 'Food'}) =>
    DiaryEntry(
      id: id,
      name: name,
      source: DiarySources.product,
      ref: name.toLowerCase(),
      servingLabel: '100 g',
      servingGrams: 100,
      quantity: 1,
      perServing: Nutriments(kcal: kcal),
    );

void main() {
  late Directory root;
  late LocalDiaryStore store;
  final cleanup = <Directory>[];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('recibook_diary_test');
    cleanup.add(root);
    store = LocalDiaryStore(root);
  });

  tearDown(() async {
    for (final dir in cleanup) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
    cleanup.clear();
  });

  test('a saved day comes back with its numbers', () async {
    await store.save(
        DiaryDay.empty('2026-08-19').addEntry('Lunch', entry('a', kcal: 250)));
    final back = await store.load('2026-08-19');
    expect(back.total.kcal, 250);
    expect(back.meal('Lunch')!.entries.single.id, 'a');
  });

  test('a day that was never logged reads empty, not null', () async {
    final back = await store.load('2026-01-01');
    expect(back.isEmpty, isTrue);
    expect(back.date, '2026-01-01');
  });

  test('an empty day writes no file', () async {
    await store.save(DiaryDay.empty('2026-08-19'));
    expect(await File('${root.path}/2026-08-19.json').exists(), isFalse);
  });

  test('emptying a day deletes the file it had', () async {
    var day = DiaryDay.empty('2026-08-19').addEntry('Lunch', entry('a'));
    await store.save(day);
    expect(await File('${root.path}/2026-08-19.json').exists(), isTrue);
    await store.save(day.removeEntry('a'));
    expect(await File('${root.path}/2026-08-19.json').exists(), isFalse);
    expect(await store.loggedDates(), isEmpty);
  });

  test('a corrupt file reads as an empty day and is left on disk', () async {
    final file = File('${root.path}/2026-08-19.json');
    await file.create(recursive: true);
    await file.writeAsString('{not json');
    expect((await store.load('2026-08-19')).isEmpty, isTrue);
    expect(await file.exists(), isTrue);
  });

  test('a file whose contents fail validation reads as empty', () async {
    final file = File('${root.path}/2026-08-19.json');
    await file.create(recursive: true);
    await file.writeAsString(jsonEncode({'schema_version': 7, 'date': '2026-08-19'}));
    expect((await store.load('2026-08-19')).isEmpty, isTrue);
  });

  test('a bad date is refused rather than written somewhere odd', () async {
    expect(
      () => store.save(DiaryDay(date: '../escape', meals: [
        DiaryMeal(name: 'Lunch', entries: [entry('a')])
      ])),
      throwsStateError,
    );
    expect(await store.load('../escape'), isA<DiaryDay>());
  });

  test('logged dates are newest first and ignore foreign files', () async {
    for (final d in ['2026-08-17', '2026-08-19', '2026-08-18']) {
      await store.save(DiaryDay.empty(d).addEntry('Lunch', entry('a')));
    }
    await File('${root.path}/notes.txt').writeAsString('hi');
    await File('${root.path}/2026-13-99.json').writeAsString('{}');
    expect(await store.loggedDates(),
        ['2026-08-19', '2026-08-18', '2026-08-17']);
  });

  test('a re-save overwrites the day, never duplicates it', () async {
    final day = DiaryDay.empty('2026-08-19').addEntry('Lunch', entry('a'));
    await store.save(day);
    await store.save(day.addEntry('Dinner', entry('b')));
    expect((await store.load('2026-08-19')).entryCount, 2);
    expect(await store.loggedDates(), ['2026-08-19']);
  });

  group('recents', () {
    test('newest first, one row per distinct food', () async {
      await store.save(DiaryDay.empty('2026-08-17')
          .addEntry('Lunch', entry('a', name: 'Oats')));
      await store.save(DiaryDay.empty('2026-08-19')
          .addEntry('Breakfast', entry('b', name: 'Oats'))
          .addEntry('Dinner', entry('c', name: 'Rice')));
      final recents = await store.recentEntries();
      expect(recents.map((e) => e.name), ['Rice', 'Oats']);
    });

    test('the window bounds how far back it reads', () async {
      await store.save(DiaryDay.empty('2026-08-01')
          .addEntry('Lunch', entry('old', name: 'Kale')));
      await store.save(DiaryDay.empty('2026-08-19')
          .addEntry('Lunch', entry('new', name: 'Rice')));
      final recents = await store.recentEntries(days: 1);
      expect(recents.map((e) => e.name), ['Rice']);
    });

    test('the limit stops the walk', () async {
      var day = DiaryDay.empty('2026-08-19');
      for (var i = 0; i < 10; i++) {
        day = day.addEntry('Lunch', entry('e$i', name: 'Food $i'));
      }
      await store.save(day);
      expect((await store.recentEntries(limit: 3)).length, 3);
    });

    test('re-logging a recent keeps its snapshot and takes a new id', () {
      final original = entry('a', kcal: 250);
      final again = relog(original, id: 'b', quantity: 2);
      expect(again.id, 'b');
      expect(again.perServing.kcal, 250);
      expect(again.total.kcal, 500);
    });
  });
}
