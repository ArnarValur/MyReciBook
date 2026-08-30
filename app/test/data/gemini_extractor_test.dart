// GeminiExtractor over MockClient — request shape is frozen (D2: the proxy
// swap must stay ~1 h of client work, so these assertions pin the contract).
// Binding init makes rootBundle serve the real prompt/schema assets.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myrecibook/data/gemini_extractor.dart';
import 'package:myrecibook/domain/extractor.dart';

const _combineNote = 'Combine them into a single recipe';

/// What normalizeContent makes of a bare `{"title": ...}` model reply.
Map<String, Object?> _bareRecipe(String title) => {
      'title': title,
      'ingredients': <Object?>[],
      'steps': <Object?>[],
      'extraction': {
        'overall_confidence': 1.0,
        'needs_review': <Object?>[],
      },
    };

http.Response _candidateResponse(String text) => http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': text}
              ]
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('recibook_extractor_test');
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<File> image(String name, List<int> bytes) =>
      File('${tmp.path}/$name').writeAsBytes(bytes);

  GeminiExtractor extractor(MockClient client) =>
      GeminiExtractor(apiKey: 'test-key', client: client);

  test('200 with plain JSON body → parsed content', () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = extractor(MockClient(
        (_) async => _candidateResponse('{"title": "Pancakes", "steps": []}')));
    expect(await ex.extractContent([img]), _bareRecipe('Pancakes'));
  });

  test('UTF-8 body without charset header keeps ½ intact (no latin1 fallback)',
      () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = extractor(MockClient((_) async => http.Response.bytes(
          utf8.encode(jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': '{"title": "½ teaspoon vanilla"}'}
                  ]
                }
              }
            ]
          })),
          200,
          headers: {'content-type': 'application/json'},
        )));
    expect(await ex.extractContent([img]), _bareRecipe('½ teaspoon vanilla'));
  });

  test('200 with ```json fenced text → fences stripped', () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = extractor(MockClient((_) async =>
        _candidateResponse('```json\n{"title": "Fenced"}\n```')));
    expect(await ex.extractContent([img]), _bareRecipe('Fenced'));
  });

  for (final (status, retryable) in [(429, true), (503, true), (400, false)]) {
    test('$status → ExtractionException, retryable=$retryable', () async {
      final img = await image('a.jpg', [1, 2, 3]);
      final ex = extractor(
          MockClient((_) async => http.Response('overloaded', status)));
      await expectLater(
        ex.extractContent([img]),
        throwsA(isA<ExtractionException>()
            .having((e) => e.httpStatus, 'httpStatus', status)
            .having((e) => e.retryable, 'retryable', retryable)),
      );
    });
  }

  test('ClientException (transport) → ExtractionException, retryable',
      () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = extractor(
        MockClient((_) => throw http.ClientException('connection reset')));
    await expectLater(
      ex.extractContent([img]),
      throwsA(isA<ExtractionException>()
          .having((e) => e.httpStatus, 'httpStatus', isNull)
          .having((e) => e.retryable, 'retryable', isTrue)),
    );
  });

  test('timeout → ExtractionException, retryable', () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = GeminiExtractor(
        apiKey: 'test-key',
        timeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));
          return _candidateResponse('{}');
        }));
    await expectLater(
      ex.extractContent([img]),
      throwsA(isA<ExtractionException>()
          .having((e) => e.httpStatus, 'httpStatus', isNull)
          .having((e) => e.retryable, 'retryable', isTrue)),
    );
  });

  test('empty api key throws before any request', () async {
    final img = await image('a.jpg', [1, 2, 3]);
    var requests = 0;
    final ex = GeminiExtractor(
        apiKey: '',
        client: MockClient((_) async {
          requests++;
          return _candidateResponse('{}');
        }));
    await expectLater(
      ex.extractContent([img]),
      throwsA(isA<ExtractionException>()
          .having((e) => e.httpStatus, 'httpStatus', isNull)),
    );
    expect(requests, 0);
  });

  test('unparseable candidate text → ExtractionException', () async {
    final img = await image('a.jpg', [1, 2, 3]);
    final ex = extractor(
        MockClient((_) async => _candidateResponse('sorry, no recipe here')));
    await expectLater(
        ex.extractContent([img]), throwsA(isA<ExtractionException>()));
  });

  test('multi-image: combine note + one inline_data per image, correct mime',
      () async {
    final jpg = await image('shot1.jpg', [10, 11]);
    final png = await image('shot2.PNG', [20, 21]);
    late Map<String, dynamic> sent;
    final ex = extractor(MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return _candidateResponse('{"title": "x"}');
    }));

    await ex.extractContent([jpg, png]);

    final parts =
        ((sent['contents'] as List).single as Map)['parts'] as List;
    expect(parts, hasLength(3)); // prompt text + 2 images
    expect(parts[0]['text'], contains(_combineNote));
    expect(parts[1]['inline_data'], {
      'mime_type': 'image/jpeg',
      'data': base64Encode([10, 11]),
    });
    expect(parts[2]['inline_data'], {
      'mime_type': 'image/png',
      'data': base64Encode([20, 21]),
    });
    expect(sent['generationConfig'],
        {'response_mime_type': 'application/json', 'temperature': 0.1});
  });

  test('single image: no combine note', () async {
    final jpg = await image('only.jpg', [1]);
    late Map<String, dynamic> sent;
    final ex = extractor(MockClient((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return _candidateResponse('{"title": "x"}');
    }));

    await ex.extractContent([jpg]);

    final parts =
        ((sent['contents'] as List).single as Map)['parts'] as List;
    expect(parts, hasLength(2));
    expect(parts[0]['text'], isNot(contains(_combineNote)));
    expect(parts[1]['inline_data'],
        {'mime_type': 'image/jpeg', 'data': base64Encode([1])});
  });

  test('proxy mode: proxy URL, no key anywhere, install id rides the header',
      () async {
    final img = await image('a.jpg', [1, 2, 3]);
    late http.Request seen;
    final ex = GeminiExtractor(
        proxyUrl: 'https://proxy.example',
        installId: 'install-1234',
        client: MockClient((request) async {
          seen = request;
          return _candidateResponse('{"title": "x"}');
        }));
    expect(await ex.extractContent([img]), _bareRecipe('x'));
    expect(seen.url.toString(),
        'https://proxy.example/v1beta/models/gemini-3.5-flash-lite:generateContent');
    expect(seen.headers['X-Install-Id'], 'install-1234');
    expect(seen.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('x-goog-api-key')));
  });

  test('neither proxy nor key configured → honest ExtractionException',
      () async {
    final img = await image('a.jpg', [1]);
    final ex = GeminiExtractor(
        apiKey: '',
        proxyUrl: '',
        client: MockClient((_) async => _candidateResponse('{}')));
    await expectLater(
        ex.extractContent([img]), throwsA(isA<ExtractionException>()));
  });

  group('normalizeContent (model shape → v1 content shape)', () {
    test('bucket confidence maps to floats, worst becomes overall', () {
      final content = GeminiExtractor.normalizeContent({
        'title': 'Filled Cookies',
        'ingredients': [
          {
            'raw': '1 teaspoon each of soda Cream of tarter & baking powder',
            'line_id': 'l7',
            'item': 'soda',
            'confidence': 'certain',
          },
          {
            'raw': '1 teaspoon each of soda Cream of tarter & baking powder',
            'line_id': 'l7',
            'item': 'baking powder',
            'confidence': 'probable',
          },
        ],
        'steps': [
          {'raw': 'roll out & cut', 'confidence': 'guess'},
        ],
        'needs_review': ['steps[0].raw'],
      });

      final ings = content['ingredients'] as List;
      expect((ings[0] as Map)['confidence'], 1.0);
      expect((ings[0] as Map)['line_id'], 'l7');
      expect((ings[1] as Map)['confidence'], 0.6);
      expect(((content['steps'] as List)[0] as Map)['confidence'], 0.3);
      final extraction = content['extraction'] as Map;
      expect(extraction['overall_confidence'], 0.3);
      expect(extraction['needs_review'], ['steps[0].raw']);
      expect(content.containsKey('needs_review'), isFalse);
    });

    test('all certain → overall 1.0, clears the batch auto-save bar', () {
      final content = GeminiExtractor.normalizeContent({
        'title': 'x',
        'ingredients': [
          {'raw': '3 cups sugar', 'line_id': 'l1', 'confidence': 'certain'},
        ],
        'steps': [
          {'raw': 'Mix', 'confidence': 'certain'},
        ],
        'needs_review': <Object?>[],
      });
      expect((content['extraction'] as Map)['overall_confidence'], 1.0);
    });

    test('app_hint lands in source.app_hint on the screenshot path', () {
      final content = GeminiExtractor.normalizeContent({
        'title': 'x',
        'app_hint': 'allrecipes.com',
        'ingredients': <Object?>[],
        'steps': <Object?>[],
      });
      expect(content['source'], {'app_hint': 'allrecipes.com'});
      expect(content.containsKey('app_hint'), isFalse);
    });

    test('numeric confidence from an old-style reply passes through', () {
      final content = GeminiExtractor.normalizeContent({
        'title': 'x',
        'ingredients': [
          {'raw': '1 cup milk', 'confidence': 0.7},
        ],
        'steps': <Object?>[],
      });
      expect(((content['ingredients'] as List)[0] as Map)['confidence'], 0.7);
      expect((content['extraction'] as Map)['overall_confidence'], 0.7);
    });
  });
}
