// Extractor interface (architecture §3.2). Per D3 only the winning spike arm
// gets an implementation; mode values match the schema enum.

import 'dart:io';

abstract class Extractor {
  /// Stamped into extraction.mode: "image" | "ocr_text".
  String get mode;

  /// Model identifier stamped into extraction.model.
  String get modelName;

  /// Returns the model's parsed content JSON (subset — no envelope fields).
  /// Throws [ExtractionException] on transport, rate-limit or parse failure.
  Future<Map<String, dynamic>> extractContent(List<File> images);
}

class ExtractionException implements Exception {
  final String message;
  final int? httpStatus;

  /// The proxy's `error` word on a refusal — 'rate_limited', 'daily_limit',
  /// 'cap_exceeded', 'busy' — so the UI can say which of the three 429s it
  /// met instead of "try again shortly" to all of them. Null when the body
  /// carried none (direct Gemini, transport failure, 5xx).
  final String? reason;

  /// Rate limits and 5xx are worth an automatic retry; 4xx are not.
  bool get retryable =>
      httpStatus == null || httpStatus == 429 || (httpStatus! >= 500);

  /// The included grant is spent. Retrying spends nothing and changes
  /// nothing — the honest next step is typing it in, or a top-up.
  bool get capExhausted => reason == 'cap_exceeded';

  /// Today's spend-rate ceiling, not the allowance: it opens again tomorrow.
  bool get dailyLimit => reason == 'daily_limit';

  ExtractionException(this.message, {this.httpStatus, this.reason});

  @override
  String toString() => 'ExtractionException($httpStatus): $message';
}


/// Reading a grocery product's packaging — a separate capability from
/// extracting a recipe, so a build or a test that has one need not have the
/// other. GeminiExtractor implements both; the pantry asks for this one and
/// hides its button when nothing provides it (the dead-end rule).
abstract class LabelReader {
  /// Raw model JSON. domain/label_read.dart is what refuses to trust it.
  Future<Map<String, dynamic>> extractLabel(List<File> images);
}
