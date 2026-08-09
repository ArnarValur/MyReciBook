// Cloud Run entrypoint. All config via env:
//   GEMINI_API_KEY     required — refuses to boot without it
//   ALLOWED_MODELS     comma-separated, default gemini-3.6-flash
//   FREE_MONTHLY_CAP   per-install per-month, default 100
//   PORT               injected by Cloud Run, default 8080

import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:myrecibook_proxy/proxy.dart';

Future<void> main() async {
  final key = Platform.environment['GEMINI_API_KEY'] ?? '';
  if (key.isEmpty) {
    stderr.writeln('GEMINI_API_KEY is not set — refusing to start.');
    exit(1);
  }
  final models = (Platform.environment['ALLOWED_MODELS'] ?? 'gemini-3.6-flash')
      .split(',')
      .map((m) => m.trim())
      .where((m) => m.isNotEmpty)
      .toSet();
  final cap =
      int.tryParse(Platform.environment['FREE_MONTHLY_CAP'] ?? '') ?? 100;
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

  final handler = const Pipeline()
      // Method + path + status only — request bodies are recipe content and
      // never touch a log (context.md constraint 3).
      .addMiddleware(logRequests())
      .addHandler(buildHandler(ProxyConfig(
        geminiApiKey: key,
        allowedModels: models,
        monthlyCapPerInstall: cap,
      )));

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln('extraction proxy listening on :${server.port} '
      '(models: ${models.join(', ')}, cap: $cap/install/month)');
}
