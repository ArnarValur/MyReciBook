// A user-invented recipe tag: what it is called, what it looks like.
//
// The split that makes this safe:
//   MEMBERSHIP lives in the recipe file — "tags": ["Weeknight"] in <id>.json.
//     User-owned, syncs, survives a reinstall, readable by a human.
//   DECORATION lives here, in tags.json beside the recipes.
//
// The recipe files WIN. If tags.json is missing or corrupt the app still
// lists every tag string it finds across the library and draws it plain. A
// tag can lose its outfit; it can never be lost.

import 'tag_icons.dart';

/// The eight tints a tag may wear. Names, not hex: the actual colours come
/// from the theme, so a tag looks right in both light and dark and follows
/// the palette if it ever moves.
enum TagColor { primary, red, orange, amber, green, teal, blue, purple }

/// Unknown or absent colour reads as [TagColor.primary] — a corrupt entry is
/// a default, not a crash.
TagColor parseTagColor(String? v) => switch (v) {
      'red' => TagColor.red,
      'orange' => TagColor.orange,
      'amber' => TagColor.amber,
      'green' => TagColor.green,
      'teal' => TagColor.teal,
      'blue' => TagColor.blue,
      'purple' => TagColor.purple,
      _ => TagColor.primary,
    };

String tagColorName(TagColor c) => c.name;

class RecipeTag {
  RecipeTag({
    required this.name,
    this.icon,
    this.color = TagColor.primary,
    bool showLabel = true,
  })
  // Two fields, not three modes. A tag with no icon MUST show its label,
  // because the alternative — no icon and no label — is a blank chip, and a
  // blank chip is not a thing a user can be allowed to make by accident.
  : showLabel = icon == null ? true : showLabel;

  /// The identity. Two tags cannot share a name; they would be the same tag.
  /// Renaming rewrites the recipe files that carry it — the alternative
  /// ("tags": ["t_8f2a"]) makes the user's own file unreadable, which the bet
  /// forbids.
  final String name;

  /// A catalog key from tag_icons.dart, OR a literal emoji the user typed.
  /// [isTagIconKey] tells them apart. Null = label-only tag.
  final String? icon;

  final TagColor color;

  /// icon + showLabel  → pill:   ⚡ Weeknight
  /// icon, no label    → circle: ⚡          (the only form that fits on a
  ///                              grid cover card beside the heart)
  /// no icon           → label only, forced true by the constructor.
  final bool showLabel;

  bool get isEmojiIcon => icon != null && !isTagIconKey(icon!);

  /// Tag names are compared case-insensitively and trimmed: "Weeknight" and
  /// "weeknight " are one tag, and letting both exist would make the filter
  /// row lie about how many tags there are.
  static String canonical(String name) => name.trim().toLowerCase();

  /// A name that can be stored. Empty or whitespace-only is not a tag.
  static bool isValidName(String name) => name.trim().isNotEmpty;

  RecipeTag copyWith({
    String? name,
    String? icon,
    bool clearIcon = false,
    TagColor? color,
    bool? showLabel,
  }) =>
      RecipeTag(
        name: name ?? this.name,
        icon: clearIcon ? null : (icon ?? this.icon),
        color: color ?? this.color,
        showLabel: showLabel ?? this.showLabel,
      );

  /// Absent fields are omitted rather than written null, so a plain tag stays
  /// a one-line object in a file the user may well read.
  Map<String, dynamic> toJson() => {
        'name': name,
        if (icon != null) 'icon': icon,
        if (color != TagColor.primary) 'color': tagColorName(color),
        if (!showLabel) 'showLabel': false,
      };

  /// Null when the entry carries no usable name — a decoration with nothing
  /// to decorate is dropped rather than allowed to become a ghost tag.
  static RecipeTag? fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || !isValidName(name)) return null;
    final icon = json['icon'];
    return RecipeTag(
      name: name.trim(),
      icon: icon is String && icon.trim().isNotEmpty ? icon.trim() : null,
      color: parseTagColor(json['color'] as String?),
      showLabel: json['showLabel'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'RecipeTag($name)';
}
