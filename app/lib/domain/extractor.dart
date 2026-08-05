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
