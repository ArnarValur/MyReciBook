// Arm A extractor: images straight to a flash-class vision model.
// Request shape mirrors the proven spike harness (spike/harness.py).
//
// Two transports, same request:
//  - EXTRACTION_PROXY_URL set → the D2 proxy (proxy/): no key on the device,
//    X-Install-Id header feeds the fair-use counter. Production mode.
//  - else GEMINI_API_KEY via --dart-define → direct Gemini, key on device.
//    Dev/closed-track mode only; a public build must never ship this way
//    (senior review F3).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../domain/extractor.dart';

class GeminiExtractor implements Extractor, LabelReader {
  // Flash-Lite for cost (Arnar 2026-08-19): same multimodal input, a
  // fraction of the price per extraction, and the fair-use cap in the
  // listing is what this bill has to fit inside. Still vision-capable —
  // screenshots go straight in, unchanged.
  static const _defaultModel = 'gemini-3.5-flash-lite';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _proxyUrl = String.fromEnvironment('EXTRACTION_PROXY_URL');

  final String model;
  final String apiKey;
  final String proxyUrl;

  /// Anonymous per-install id (install_id.dart) — the proxy's counter KEY,
  /// never its proof of identity. Only sent in proxy mode.
  final String installId;

  /// Supplies the App Check token that proves this is really our app on a
  /// real device (audit B1). Null — no Firebase in this build — means the
  /// header is simply absent, which the proxy accepts only while it runs
  /// unenforced. Returning null per call is equally survivable.
  final Future<String?> Function()? appCheckToken;

  final Duration timeout;
  final http.Client _client;

  GeminiExtractor(
      {this.model = _defaultModel,
      String? apiKey,
      String? proxyUrl,
      this.installId = '',
      this.appCheckToken,
      this.timeout = const Duration(seconds: 120),
      http.Client? client})
      : apiKey = apiKey ?? _apiKey,
        proxyUrl = proxyUrl ?? _proxyUrl,
        _client = client ?? http.Client();

  @override
  String get mode => 'image';

  @override
  String get modelName => model;

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    var prompt = await _prompt();
    if (images.length > 1) {
      prompt += '\n\nNOTE: the images are consecutive screenshots of ONE recipe, '
          'in order. Combine them into a single recipe.';
    }
    return normalizeContent(await _generate([
      {'text': prompt},
      for (final img in images)
        {
          'inline_data': {
            'mime_type': img.path.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg',
            'data': base64Encode(await img.readAsBytes()),
          }
        },
    ]));
  }

  /// Link-import fallback (share-links spike): a page with no JSON-LD recipe
  /// goes through the same prompt as page TEXT instead of screenshots. Costs
  /// an AI call like any screenshot import.
  Future<Map<String, dynamic>> extractContentFromText(String pageText) async {
    final prompt = '${await _prompt()}'
        '\n\nNOTE: instead of screenshots, the input below is the readable '
        'text of ONE web page containing the recipe. Ignore navigation, ads '
        'and comments.\n\nPAGE TEXT:\n$pageText';
    return normalizeContent(await _generate([
      {'text': prompt}
    ]));
  }

  /// Read a grocery product's packaging instead of a recipe. Same transport,
  /// same App Check header, same fair-use slot — a label read costs exactly
  /// what a screenshot import costs, which is why it is a deliberate tap and
  /// never automatic.
  ///
  /// Returns the model's raw JSON; domain/label_read.dart is what turns it
  /// into something the pantry will store, and what refuses to trust it.
  @override
  Future<Map<String, dynamic>> extractLabel(List<File> images) async {
    final prompt = await rootBundle.loadString('assets/label_prompt.md');
    return _generate([
      {'text': prompt},
      for (final img in images)
        {
          'inline_data': {
            'mime_type': img.path.toLowerCase().endsWith('.png')
                ? 'image/png'
                : 'image/jpeg',
            'data': base64Encode(await img.readAsBytes()),
          }
        },
    ]);
  }

  Future<String> _prompt() async {
    // extract.schema.json is the model-facing trim of recipe.schema.json:
    // no id/timestamps/model fields (the app fills those and the model was
    // caught inventing them), bucket confidence, line_id, top-level
    // needs_review. See docs/handoff-extraction-trim.md.
    final base = await rootBundle.loadString('assets/structure_prompt.md');
    final schema = await rootBundle.loadString('assets/extract.schema.json');
    return '$base\n\nTARGET JSON SCHEMA:\n$schema';
  }

  /// Folds the model-facing output shape back into the v1 content shape the
  /// rest of the app consumes: bucket confidence ("certain"/"probable"/
  /// "guess") becomes the stored float, top-level needs_review moves under
  /// extraction, and overall_confidence is derived as the worst line — so the
  /// batch auto-save bar (0.8) holds exactly the recipes with a non-certain
  /// line. line_id rides through untouched.
  static Map<String, dynamic> normalizeContent(Map<String, dynamic> content) {
    const buckets = {'certain': 1.0, 'probable': 0.6, 'guess': 0.3};
    double worst = 1.0;
    List<Map<String, dynamic>> mapLines(List<dynamic>? lines) => [
          for (final l in lines ?? const [])
            if (l is Map<String, dynamic>)
              {
                ...l,
                if (l['confidence'] is String)
                  'confidence': buckets[l['confidence']] ?? 0.3,
              }
        ];
    final ingredients = mapLines(content['ingredients'] as List?);
    final steps = mapLines(content['steps'] as List?);
    for (final l in ingredients.followedBy(steps)) {
      final c = (l['confidence'] as num?)?.toDouble();
      if (c != null && c < worst) worst = c;
    }
    return {
      ...content,
      'ingredients': ingredients,
      'steps': steps,
      if (content['app_hint'] != null && content['source'] is! Map)
        'source': {'app_hint': content['app_hint']},
      'extraction': {
        'overall_confidence': worst,
        'needs_review': [
          for (final p in (content['needs_review'] as List? ?? const [])) '$p'
        ],
      },
    }
      ..remove('needs_review')
      ..remove('app_hint');
  }

  Future<Map<String, dynamic>> _generate(
      List<Map<String, dynamic>> parts) async {
    final viaProxy = proxyUrl.isNotEmpty;
    if (!viaProxy && apiKey.isEmpty) {
      throw ExtractionException('No API key — build with '
          '--dart-define=GEMINI_API_KEY=... or EXTRACTION_PROXY_URL=...');
    }
    final uri = viaProxy
        ? Uri.parse('$proxyUrl/v1beta/models/$model:generateContent')
        : Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
    // Fetched per call, but the Firebase SDK caches and pre-refreshes, so
    // this is a memory read in the common case. Only the proxy path needs it:
    // Gemini direct is a dev-only mode and has no App Check.
    final token = viaProxy ? await appCheckToken?.call() : null;
    final http.Response resp;
    try {
      resp = await _client
          .post(uri,
              headers: {
                'Content-Type': 'application/json',
                if (viaProxy) 'X-Install-Id': installId,
                'X-Firebase-AppCheck': ?token,
              },
              body: jsonEncode({
                'contents': [
                  {'parts': parts}
                ],
                'generationConfig': {
                  'response_mime_type': 'application/json',
                  'temperature': 0.1,
                },
              }))
          .timeout(timeout);
    } on SocketException catch (e) {
      throw ExtractionException('offline: ${e.message}');
    } on TimeoutException {
      throw ExtractionException('no response after ${timeout.inSeconds} s');
    } on http.ClientException catch (e) {
      throw ExtractionException('offline: ${e.message}');
    } on IOException catch (e) {
      // e.g. HandshakeException on captive-portal WiFi — the extractor
      // contract (extractor.dart) is ExtractionException on any transport
      // failure, so the review screen's failed→retry (D5) always triggers.
      throw ExtractionException('offline: $e');
    }
    if (resp.statusCode != 200) {
      throw ExtractionException(resp.body, httpStatus: resp.statusCode);
    }

    try {
      // bodyBytes + utf8: package:http falls back to latin1 when the response
      // omits a charset, which mojibakes ½/⅓/é — common in recipe text.
      // allowMalformed keeps truly foreign bytes from crashing the parse.
      final body = jsonDecode(utf8.decode(resp.bodyBytes, allowMalformed: true))
          as Map<String, dynamic>;
      var text = (((body['candidates'] as List).first as Map)['content']
          as Map)['parts'][0]['text'] as String;
      text = text
          .trim()
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), '');
      return jsonDecode(text) as Map<String, dynamic>;
    } on ExtractionException {
      rethrow;
    } catch (e) {
      throw ExtractionException('unparseable model response: $e');
    }
  }
}
