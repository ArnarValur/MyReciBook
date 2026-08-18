// Link extractor (share-links spike): the JSON-LD parser against the shapes
// real recipe sites ship — HowToStep lists, @graph nesting, string
// instructions, sections, entities — and the transport contract
// (ExtractionException on refusal/offline/no-data) via a mocked client.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/link_extractor.dart';
import 'package:myrecibook/domain/extractor.dart';

String page(String jsonLd) => '''
<!doctype html><html><head>
<script type="application/ld+json">$jsonLd</script>
</head><body>hi</body></html>''';

void main() {
  group('recipeContentFromHtml', () {
    test('maps a full recipe: HowToStep list, yield, times, keywords', () {
      final content = recipeContentFromHtml(page('''
      {
        "@context": "https://schema.org",
        "@type": "Recipe",
        "name": "Skillet Lasagna",
        "inLanguage": "en",
        "recipeYield": ["4", "4 servings"],
        "prepTime": "PT15M",
        "cookTime": "PT45M",
        "totalTime": "PT1H",
        "keywords": "pasta, weeknight",
        "recipeCuisine": "Italian",
        "recipeIngredient": ["1 lb ground beef", "9 lasagna noodles"],
        "recipeInstructions": [
          {"@type": "HowToStep", "text": "Brown the beef."},
          {"@type": "HowToStep", "text": "Add noodles and simmer."}
        ]
      }'''))!;

      expect(content['title'], 'Skillet Lasagna');
      expect(content['lang'], 'en');
      expect(content['servings'], {'amount': 4, 'raw': '4'});
      expect(content['times'],
          {'prep_min': 15, 'cook_min': 45, 'total_min': 60, 'raw': null});
      expect([for (final i in content['ingredients'] as List) i['raw']],
          ['1 lb ground beef', '9 lasagna noodles']);
      expect([for (final s in content['steps'] as List) s['raw']],
          ['Brown the beef.', 'Add noodles and simmer.']);
      expect(content['tags'], ['Italian', 'pasta', 'weeknight']);
      // Verbatim site data — full confidence, nothing flagged.
      expect((content['ingredients'] as List).first['confidence'], 1.0);
      expect(content['extraction'],
          {'overall_confidence': 1.0, 'needs_review': <String>[]});
    });

    test('finds the recipe inside @graph with an array @type', () {
      final content = recipeContentFromHtml(page('''
      {
        "@context": "https://schema.org",
        "@graph": [
          {"@type": "WebSite", "name": "Some Blog"},
          {"@type": ["Recipe", "NewsArticle"], "name": "Buns",
           "recipeIngredient": ["flour", "yeast"],
           "recipeInstructions": "Knead.\\nBake."}
        ]
      }'''))!;
      expect(content['title'], 'Buns');
      expect([for (final s in content['steps'] as List) s['raw']],
          ['Knead.', 'Bake.']);
    });

    test('flattens HowToSections and strips tags/entities', () {
      final content = recipeContentFromHtml(page('''
      {
        "@type": "Recipe",
        "name": "Tacos &amp; Salsa",
        "recipeIngredient": ["2 &frac12; cups corn"],
        "recipeInstructions": [
          {"@type": "HowToSection", "name": "Salsa", "itemListElement": [
            {"@type": "HowToStep", "text": "<p>Chop &amp; mix.</p>"}
          ]},
          {"@type": "HowToSection", "name": "Tacos", "itemListElement": [
            {"@type": "HowToStep", "text": "Warm the shells at 180&deg;C."}
          ]}
        ]
      }'''))!;
      expect(content['title'], 'Tacos & Salsa');
      expect((content['ingredients'] as List).first['raw'], '2 ½ cups corn');
      expect([for (final s in content['steps'] as List) s['raw']],
          ['Chop & mix.', 'Warm the shells at 180°C.']);
    });

    test('skips a broken JSON-LD block and reads the next one', () {
      final html = '''
      <script type="application/ld+json">{not json at all</script>
      <script type="application/ld+json">
        {"@type": "Recipe", "name": "Soup",
         "recipeIngredient": ["water", "salt"],
         "recipeInstructions": "Boil."}
      </script>''';
      expect(recipeContentFromHtml(html)!['title'], 'Soup');
    });

    test('page without a Recipe node → null', () {
      expect(
          recipeContentFromHtml(
              page('{"@type": "NewsArticle", "name": "Not food"}')),
          isNull);
      expect(recipeContentFromHtml('<html><body>plain page</body></html>'),
          isNull);
    });
  });

  group('isoDurationMinutes', () {
    test('parses the shapes sites actually emit', () {
      expect(isoDurationMinutes('PT45M'), 45);
      expect(isoDurationMinutes('PT1H30M'), 90);
      expect(isoDurationMinutes('P0DT1H0M'), 60);
      expect(isoDurationMinutes('PT90S'), 1.5);
    });

    test('rejects junk rather than guessing', () {
      expect(isoDurationMinutes('0:45'), isNull);
      expect(isoDurationMinutes('45 minutes'), isNull);
      expect(isoDurationMinutes(null), isNull);
      expect(isoDurationMinutes('PT0M'), isNull);
    });
  });

  group('LinkExtractor', () {
    const url = 'https://example.com/best-buns';

    LinkExtractor withResponse(http.Response Function(http.Request) handler) =>
        LinkExtractor(url: url, client: MockClient((r) async => handler(r)));

    test('200 with JSON-LD → content stamped with link source', () async {
      final extractor = withResponse((r) {
        expect(r.url.toString(), url);
        expect(r.headers['User-Agent'], contains('Mozilla'));
        return http.Response(
            page('{"@type":"Recipe","name":"Buns",'
                '"recipeIngredient":["flour","yeast"],'
                '"recipeInstructions":"Bake."}'),
            200);
      });
      final content = await extractor.extractContent(const <File>[]);
      expect(content['title'], 'Buns');
      expect(content['source'],
          {'type': 'link', 'url': url, 'app_hint': 'example.com'});
      expect(extractor.mode, 'link');
      expect(extractor.modelName, 'jsonld');
    });

    test('non-200 → ExtractionException with the status (not retryable)',
        () async {
      final extractor = withResponse((_) => http.Response('nope', 403));
      try {
        await extractor.extractContent(const <File>[]);
        fail('should throw');
      } on ExtractionException catch (e) {
        expect(e.httpStatus, 403);
        expect(e.retryable, isFalse);
        expect(e.message, startsWith('the page answered'));
      }
    });

    test('page without recipe data → "no recipe data" message', () async {
      final extractor =
          withResponse((_) => http.Response('<html>no recipe</html>', 200));
      expect(
          () => extractor.extractContent(const <File>[]),
          throwsA(isA<ExtractionException>().having(
              (e) => e.message, 'message', startsWith('no recipe data'))));
    });

    test('parse failure (chunked trailers) is NOT "offline"', () async {
      // Fastly's server-timing trailer kills dart:io's parser on every
      // Hearst site; the copy must not blame the user's connection.
      final extractor = LinkExtractor(
          url: url,
          client: MockClient((_) async => throw http.ClientException(
              'Failed to parse HTTP, 115 does not match 13')));
      expect(
          () => extractor.extractContent(const <File>[]),
          throwsA(isA<ExtractionException>().having((e) => e.message,
              'message', startsWith('unreadable response'))));
    });

    test('no JSON-LD + fallback → page text goes through the AI seam',
        () async {
      const page = '''
      <html><head>
      <meta property="og:image" content="https://example.com/hero.jpg">
      <script>ignore me entirely</script>
      </head><body>
      <h1>Lemon Cake</h1><p>Mix 2 cups flour with 1 cup sugar.</p>
      <p>Bake it well and enjoy the result with friends and family.</p>
      <p>This bright, tender lemon cake came from my grandmother's box of
      handwritten cards, and it has opened every summer gathering since.
      Serve it with softly whipped cream and the ripest berries you can
      find at the market that morning.</p>
      </body></html>''';
      String? seenText;
      final extractor = LinkExtractor(
        url: url,
        client: MockClient((_) async => http.Response(page, 200)),
        fallbackModel: 'fake-gemini',
        fallback: (text) async {
          seenText = text;
          return {
            'title': 'Lemon Cake',
            'ingredients': [
              {'raw': '2 cups flour'},
              {'raw': '1 cup sugar'},
            ],
            'steps': [
              {'raw': 'Bake it well.'},
            ],
          };
        },
      );
      final content = await extractor.extractContent(const <File>[]);
      expect(seenText, contains('Mix 2 cups flour'));
      expect(seenText, isNot(contains('ignore me'))); // scripts stripped
      expect(content['title'], 'Lemon Cake');
      // The AI never saw the page's markup — og:image fills the cover seam.
      expect(content['image_url'], 'https://example.com/hero.jpg');
      expect((content['source'] as Map)['url'], url);
      expect(extractor.modelName, 'fake-gemini'); // honest extraction stamp
    });

    test('fallback returning an empty shell still fails as "no recipe"',
        () async {
      final extractor = LinkExtractor(
        url: url,
        client: MockClient((_) async => http.Response(
            '<html><body>${'Just a news article about food politics. ' * 20}'
            '</body></html>',
            200)),
        fallback: (_) async => {
          'title': 'Not food',
          'ingredients': <Object?>[],
          'steps': <Object?>[],
        },
      );
      expect(
          () => extractor.extractContent(const <File>[]),
          throwsA(isA<ExtractionException>().having(
              (e) => e.message, 'message', startsWith('no recipe data'))));
      expect(extractor.modelName, 'jsonld'); // nothing was extracted by AI
    });

    test('transport failure → offline message (retryable)', () async {
      final extractor = LinkExtractor(
          url: url,
          client: MockClient((_) async =>
              throw http.ClientException('Connection failed')));
      try {
        await extractor.extractContent(const <File>[]);
        fail('should throw');
      } on ExtractionException catch (e) {
        expect(e.message, startsWith('offline'));
        expect(e.retryable, isTrue);
      }
    });
  });
}
