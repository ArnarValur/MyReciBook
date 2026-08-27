// SafTagStore: tags.json read/write, and the stance that a broken decoration
// file costs icons rather than tags.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/tag_store.dart';
import 'package:myrecibook/domain/recipe_tag.dart';

import 'fake_saf_channel.dart';

void main() {
  // The fake installs a mock method-channel handler, which needs the binding.
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSafChannel fake;
  late SafTagStore store;

  setUp(() {
    fake = FakeSafChannel()..install();
    store = SafTagStore(treeUri: fake.treeUri, channel: fake.channel);
  });

  tearDown(() => fake.uninstall());

  test('no tags.json is an empty list, never an error', () async {
    expect(await store.load(), isEmpty);
  });

  test('saves and reads back, defaults and all', () async {
    await store.save([
      RecipeTag(name: 'Weeknight', icon: 'quick', color: TagColor.amber),
      RecipeTag(name: 'Sunday', icon: '🥘', showLabel: false),
      RecipeTag(name: 'Plain'),
    ]);

    final back = await SafTagStore(treeUri: fake.treeUri, channel: fake.channel)
        .load();
    expect(back.map((t) => t.name), ['Weeknight', 'Sunday', 'Plain']);
    expect(back[0].color, TagColor.amber);
    expect(back[1].isEmojiIcon, isTrue);
    expect(back[1].showLabel, isFalse);
    expect(back[2].icon, isNull);
  });

  test('a corrupt file reads as empty — plain tags, never a crash', () async {
    fake.seedFile(kTagsFileName, utf8.encode('{not json'),
        mime: 'application/json');
    expect(await store.load(), isEmpty);
  });

  test('a duplicate name in the file is one tag, first wins', () async {
    fake.seedFile(
      kTagsFileName,
      utf8.encode(jsonEncode({
        'tags': [
          {'name': 'Weeknight', 'color': 'red'},
          {'name': 'weeknight ', 'color': 'blue'},
          {'icon': 'quick'}, // no name: dropped
        ]
      })),
      mime: 'application/json',
    );
    final back = await store.load();
    expect(back.length, 1);
    expect(back.single.color, TagColor.red);
  });

  test('a second save reuses the same file, never "tags (1).json"', () async {
    await store.save([RecipeTag(name: 'One')]);
    await store.save([RecipeTag(name: 'Two')]);
    final names = [
      for (final d in fake.childrenOf(FakeSafChannel.rootId))
        if (d.name.startsWith('tags')) d.name
    ];
    expect(names, [kTagsFileName]);
    expect((await store.load()).single.name, 'Two');
  });
}
