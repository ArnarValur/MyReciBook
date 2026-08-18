// Link extractor (share-links spike): a shared URL instead of screenshots.
// Fetches the page and reads the schema.org Recipe JSON-LD most recipe sites
// embed — verbatim site data, so no AI call and confidence 1.0. No JSON-LD
// recipe on the page → ExtractionException; the review screen's failed state
// tells the user to screenshot instead. Implements Extractor so the whole
// review flow (spinner → failed/retry → review) works unchanged; the images
// argument is ignored.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/extractor.dart';

class LinkExtractor implements Extractor {
  LinkExtractor({
    required this.url,
    this.timeout = const Duration(seconds: 20),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String url;
  final Duration timeout;
  final http.Client _client;

  // Plain-browser UA: default Dart UA trips the bot filters on big recipe
  // sites; the page served to a phone browser is the one with the JSON-LD.
  static const _userAgent = 'Mozilla/5.0 (Linux; Android 13; SM-G991B) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';

  @override
  String get mode => 'link';

  @override
  String get modelName => 'jsonld';

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    final Uri uri;
    try {
      uri = Uri.parse(url);
    } on FormatException {
      throw ExtractionException('not a valid link: $url');
    }
    final http.Response resp;
    try {
      resp = await _client.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'text/html,application/xhtml+xml',
      }).timeout(timeout);
    } on SocketException catch (e) {
      throw ExtractionException('offline: ${e.message}');
    } on TimeoutException {
      throw ExtractionException('no response after ${timeout.inSeconds} s');
    } on http.ClientException catch (e) {
      // A response our HTTP stack can't parse (e.g. dart:io on chunked
      // trailers) is the site's dialect, not the user's connection — saying
      // "offline" here burned a real debugging round (S21, 2026-08-19).
      if (e.message.contains('Failed to parse HTTP')) {
        throw ExtractionException('unreadable response: ${e.message}');
      }
      throw ExtractionException('offline: ${e.message}');
    } on IOException catch (e) {
      throw ExtractionException('offline: $e');
    }
    if (resp.statusCode != 200) {
      throw ExtractionException('the page answered ${resp.statusCode}',
          httpStatus: resp.statusCode);
    }
    // bodyBytes + utf8: same charset stance as GeminiExtractor — recipe text
    // is full of ½/é and a latin1 fallback mojibakes it.
    final html = utf8.decode(resp.bodyBytes, allowMalformed: true);
    final content = recipeContentFromHtml(html);
    if (content == null) {
      throw ExtractionException('no recipe data at that link');
    }
    content['source'] = {
      'type': 'link',
      'url': url,
      'app_hint': uri.host.isEmpty ? null : uri.host,
    };
    return content;
  }
}

/// First schema.org Recipe found in the page's JSON-LD blocks, mapped to the
/// extractor content shape (title/ingredients/steps/…), or null when the page
/// carries none. Pure — the testable core of [LinkExtractor].
Map<String, dynamic>? recipeContentFromHtml(String html) {
  for (final block in _jsonLdBlocks(html)) {
    Object? decoded;
    try {
      decoded = jsonDecode(block);
    } catch (_) {
      continue; // sites ship broken JSON-LD next to valid blocks
    }
    final node = _findRecipeNode(decoded, depth: 0);
    if (node != null) return _contentFromNode(node);
  }
  return null;
}

Iterable<String> _jsonLdBlocks(String html) sync* {
  final scripts = RegExp(
    '<script[^>]*type\\s*=\\s*["\']application/ld\\+json["\'][^>]*>(.*?)</script>',
    caseSensitive: false,
    dotAll: true,
  );
  for (final m in scripts.allMatches(html)) {
    final body = m.group(1)!.trim();
    if (body.isNotEmpty) yield body;
  }
}

/// Depth-capped walk: JSON-LD nests recipes under @graph, arrays and
/// mainEntity — search everything, but never follow a pathological tree.
Map<String, dynamic>? _findRecipeNode(Object? node, {required int depth}) {
  if (depth > 6) return null;
  if (node is List) {
    for (final e in node) {
      final hit = _findRecipeNode(e, depth: depth + 1);
      if (hit != null) return hit;
    }
    return null;
  }
  if (node is! Map) return null;
  final map = node.cast<String, dynamic>();
  if (_typeIncludes(map['@type'], 'Recipe')) return map;
  for (final v in map.values) {
    if (v is Map || v is List) {
      final hit = _findRecipeNode(v, depth: depth + 1);
      if (hit != null) return hit;
    }
  }
  return null;
}

bool _typeIncludes(Object? type, String wanted) =>
    type is String && type == wanted ||
    type is List && type.any((t) => t == wanted);

Map<String, dynamic> _contentFromNode(Map<String, dynamic> node) {
  final ingredients = _stringList(
      node['recipeIngredient'] ?? node['ingredients'] /* legacy key */);
  final steps = _instructionLines(node['recipeInstructions']);
  return {
    'title': _cleanText(node['name']) ?? '',
    'lang': node['inLanguage'] is String ? node['inLanguage'] : null,
    'servings': _servings(node['recipeYield'] ?? node['yield']),
    'times': _times(node),
    'ingredients': [
      for (final line in ingredients) {'raw': line, 'confidence': 1.0}
    ],
    'steps': [
      for (final line in steps) {'raw': line, 'confidence': 1.0}
    ],
    'tags': _tags(node),
    // Site-published data, quoted verbatim — nothing was guessed.
    'extraction': {'overall_confidence': 1.0, 'needs_review': <String>[]},
  };
}

Map<String, dynamic>? _servings(Object? yield_) {
  final raw = _cleanText(yield_ is List ? yield_.firstOrNull : yield_);
  if (raw == null) return null;
  final amount = num.tryParse(
      RegExp(r'\d+(?:[.,]\d+)?').firstMatch(raw)?.group(0)?.replaceAll(',', '.') ??
          '');
  return {'amount': amount, 'raw': raw};
}

Map<String, dynamic>? _times(Map<String, dynamic> node) {
  final prep = isoDurationMinutes(node['prepTime']);
  final cook = isoDurationMinutes(node['cookTime']);
  final total = isoDurationMinutes(node['totalTime']);
  if (prep == null && cook == null && total == null) return null;
  return {'prep_min': prep, 'cook_min': cook, 'total_min': total, 'raw': null};
}

/// "PT1H30M" → 90; null on anything that isn't an ISO-8601 duration.
num? isoDurationMinutes(Object? value) {
  if (value is! String) return null;
  final m = RegExp(
          r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+(?:[.,]\d+)?)M)?(?:(\d+)S)?)?$')
      .firstMatch(value.trim());
  if (m == null) return null;
  final days = int.tryParse(m.group(1) ?? '') ?? 0;
  final hours = int.tryParse(m.group(2) ?? '') ?? 0;
  final mins =
      double.tryParse((m.group(3) ?? '').replaceAll(',', '.')) ?? 0;
  final secs = int.tryParse(m.group(4) ?? '') ?? 0;
  final total = days * 1440 + hours * 60 + mins + secs / 60;
  if (total == 0) return null;
  final rounded = total.round();
  return (total - rounded).abs() < 0.001 ? rounded : total;
}

List<String> _tags(Map<String, dynamic> node) {
  final out = <String>[];
  final seen = <String>{};
  void add(Object? v) {
    if (v is List) {
      v.forEach(add);
      return;
    }
    final text = _cleanText(v);
    if (text == null) return;
    for (final part in text.split(',')) {
      final tag = part.trim();
      if (tag.isNotEmpty && tag.length <= 40 && seen.add(tag.toLowerCase())) {
        out.add(tag);
      }
    }
  }

  add(node['recipeCategory']);
  add(node['recipeCuisine']);
  add(node['keywords']);
  return out.take(8).toList();
}

List<String> _stringList(Object? value) {
  if (value is String) {
    final line = _cleanText(value);
    return line == null ? const [] : [line];
  }
  if (value is! List) return const [];
  return [
    for (final e in value)
      if (_cleanText(e) case final String line) line
  ];
}

/// recipeInstructions: a bare string, a list of strings, HowToStep objects,
/// or HowToSections wrapping either — flattened to plain step lines.
List<String> _instructionLines(Object? value) {
  if (value == null) return const [];
  if (value is String) {
    return [
      for (final part in value.split(RegExp(r'\n+')))
        if (_cleanText(part) case final String line) line
    ];
  }
  if (value is Map) {
    final map = value.cast<String, dynamic>();
    if (map['itemListElement'] != null) {
      return _instructionLines(map['itemListElement']);
    }
    final line = _cleanText(map['text'] ?? map['name']);
    return line == null ? const [] : [line];
  }
  if (value is List) {
    return [for (final e in value) ..._instructionLines(e)];
  }
  return const [];
}

/// Tag-stripped, entity-decoded, whitespace-collapsed text; null when empty
/// or not a string/number.
String? _cleanText(Object? value) {
  if (value is num) return '$value';
  if (value is! String) return null;
  final text = _decodeEntities(value.replaceAll(RegExp(r'<[^>]+>'), ' '))
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text.isEmpty ? null : text;
}

const _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'deg': '°',
  'frac12': '½',
  'frac14': '¼',
  'frac34': '¾',
};

String _decodeEntities(String text) => text.replaceAllMapped(
      RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);'),
      (m) {
        final body = m.group(1)!;
        if (body.startsWith('#')) {
          final code = body.startsWith('#x') || body.startsWith('#X')
              ? int.tryParse(body.substring(2), radix: 16)
              : int.tryParse(body.substring(1));
          return code == null ? m.group(0)! : String.fromCharCode(code);
        }
        return _namedEntities[body] ?? m.group(0)!;
      },
    );
