// Arm A extractor: images straight to a flash-class vision model.
// Request shape mirrors the proven spike harness (spike/harness.py).
//
// Key comes from --dart-define=GEMINI_API_KEY (P5: dev key behind a compile
// flag for the closed track; swaps to the thin proxy with ~1 h of client work).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../domain/extractor.dart';

class GeminiExtractor implements Extractor {
  static const _defaultModel = 'gemini-3.6-flash';
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final String model;
  final String apiKey;
  final http.Client _client;

  GeminiExtractor({this.model = _defaultModel, String? apiKey, http.Client? client})
      : apiKey = apiKey ?? _apiKey,
        _client = client ?? http.Client();

  @override
  String get mode => 'image';

  @override
  String get modelName => model;

  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) async {
    if (apiKey.isEmpty) {
      throw ExtractionException('No API key — build with --dart-define=GEMINI_API_KEY=...');
    }
    var prompt = await rootBundle.loadString('assets/structure_prompt.md');
    if (images.length > 1) {
      prompt += '\n\nNOTE: the images are consecutive screenshots of ONE recipe, '
          'in order. Combine them into a single recipe.';
    }
    final schema = await rootBundle.loadString('assets/recipe.schema.json');
    prompt += '\n\nTARGET JSON SCHEMA:\n$schema';

    final parts = <Map<String, dynamic>>[
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
    ];

    final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');
    final http.Response resp;
    try {
      resp = await _client
          .post(uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'contents': [
                  {'parts': parts}
                ],
                'generationConfig': {
                  'response_mime_type': 'application/json',
                  'temperature': 0.1,
                },
              }))
          .timeout(const Duration(seconds: 120));
    } on SocketException catch (e) {
      throw ExtractionException('offline: ${e.message}');
    }
    if (resp.statusCode != 200) {
      throw ExtractionException(resp.body, httpStatus: resp.statusCode);
    }

    try {
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
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
