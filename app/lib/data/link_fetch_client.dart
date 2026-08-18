// The HTTP client for fetching shared recipe pages (share-links spike).
//
// On Android the fetch goes through NetBridge — the platform HTTP stack —
// because dart:io's HTTP/1.1 parser dies on chunked trailers: Fastly sends a
// server-timing trailer on every Hearst recipe site (Pioneer Woman, Delish…),
// which surfaced as a bogus "You're offline" (S21, 2026-08-19). Cronet was
// the first fix but its artifacts break AGP 9's unique-namespace rule, so
// the bridge stays dependency-free. Non-Android (tests, desktop dev) uses
// the default client.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

http.Client? _cached;

http.Client linkFetchClient() =>
    _cached ??= Platform.isAndroid ? ChannelHttpClient() : http.Client();

/// package:http client whose GETs run over the NetBridge method channel.
/// Failures surface as [http.ClientException] so LinkExtractor's existing
/// transport mapping applies unchanged.
class ChannelHttpClient extends http.BaseClient {
  ChannelHttpClient(
      {this.channel = const MethodChannel('com.merkurialstudio.myrecibook/net')});

  final MethodChannel channel;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET') {
      throw http.ClientException('only GET is supported', request.url);
    }
    final Map<Object?, Object?>? reply;
    try {
      reply = await channel.invokeMethod<Map<Object?, Object?>>('get', {
        'url': request.url.toString(),
        'headers': request.headers,
      });
    } on PlatformException catch (e) {
      throw http.ClientException(e.message ?? 'native fetch failed', request.url);
    }
    final status = reply?['status'];
    final body = reply?['body'];
    if (status is! int || body is! Uint8List) {
      throw http.ClientException('malformed bridge reply', request.url);
    }
    return http.StreamedResponse(
      Stream.value(body),
      status,
      contentLength: body.length,
      request: request,
    );
  }
}
