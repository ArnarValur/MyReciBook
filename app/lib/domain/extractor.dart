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

  /// Rate limits and 5xx are worth an automatic retry; 4xx are not.
  bool get retryable =>
      httpStatus == null || httpStatus == 429 || (httpStatus! >= 500);

  ExtractionException(this.message, {this.httpStatus});

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
