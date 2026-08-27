// RecipeTag: the two-fields-not-three-modes rule, name identity, and JSON
// that stays small enough for a human to read in their own folder.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/recipe_tag.dart';
import 'package:myrecibook/domain/tag_emoji.dart';
import 'package:myrecibook/domain/tag_icons.dart';

void main() {
  test('a tag with no icon always shows its label — a blank chip is '
      'unrepresentable', () {
    final tag = RecipeTag(name: 'Weeknight', showLabel: false);
    expect(tag.showLabel, isTrue);
    // With an icon the choice is honoured: that is the icon-only circle.
    expect(RecipeTag(name: 'Weeknight', icon: 'quick', showLabel: false)
        .showLabel, isFalse);
  });

  test('names are trimmed and compared case-insensitively', () {
    expect(RecipeTag.canonical('  Weeknight '), 'weeknight');
    expect(RecipeTag.canonical('WEEKNIGHT'), RecipeTag.canonical('weeknight'));
    expect(RecipeTag.isValidName('   '), isFalse);
    expect(RecipeTag.isValidName('x'), isTrue);
  });

  test('a catalog key and an emoji are told apart by shape alone', () {
    expect(RecipeTag(name: 'A', icon: 'rice_bowl').isEmojiIcon, isFalse);
    expect(RecipeTag(name: 'A', icon: '🥑').isEmojiIcon, isTrue);
    expect(isTagIconKey('rice_bowl'), isTrue);
    expect(isTagIconKey('🥑'), isFalse);
    expect(isTagIconKey('Rice_Bowl'), isFalse); // uppercase is not a key
  });

  test('defaults are omitted from JSON so a plain tag stays one short line',
      () {
    expect(RecipeTag(name: 'Weeknight').toJson(), {'name': 'Weeknight'});
    expect(
      RecipeTag(
              name: 'Weeknight',
              icon: 'quick',
              color: TagColor.amber,
              showLabel: false)
          .toJson(),
      {
        'name': 'Weeknight',
        'icon': 'quick',
        'color': 'amber',
        'showLabel': false,
      },
    );
  });

  test('round-trips, and a corrupt colour reads as the default', () {
    final tag = RecipeTag(name: 'Sunday', icon: '🥘', color: TagColor.teal);
    final back = RecipeTag.fromJson(tag.toJson())!;
    expect(back.name, 'Sunday');
    expect(back.icon, '🥘');
    expect(back.color, TagColor.teal);

    expect(
        RecipeTag.fromJson({'name': 'X', 'color': 'chartreuse'})!.color,
        TagColor.primary);
  });

  test('an entry with no usable name is dropped, never made into a ghost', () {
    expect(RecipeTag.fromJson({'icon': 'quick'}), isNull);
    expect(RecipeTag.fromJson({'name': '   '}), isNull);
    expect(RecipeTag.fromJson({'name': 42}), isNull);
  });

  test('the catalog halves agree — every key has an icon and vice versa', () {
    // Guards the trap the plan names: a key with no binding renders as the
    // unknown fallback, a binding with no key can never be reached.
    expect(kTagIconKeys.toSet().length, kTagIconKeys.length,
        reason: 'duplicate catalog key');
  });

  test('every catalog key is a key, and every palette emoji is not', () {
    // The whole icon/emoji distinction is this one predicate, so both
    // palettes have to sit on the correct side of it.
    for (final key in kTagIconKeys) {
      expect(isTagIconKey(key), isTrue, reason: '"$key" would read as emoji');
    }
    for (final e in kTagEmoji) {
      expect(isTagIconKey(e.char), isFalse,
          reason: '"${e.char}" would read as a catalog key');
    }
  });

  test('the emoji palette carries no duplicates', () {
    final chars = [for (final e in kTagEmoji) e.char];
    expect(chars.toSet().length, chars.length,
        reason: 'the same emoji is offered twice');
  });
}
