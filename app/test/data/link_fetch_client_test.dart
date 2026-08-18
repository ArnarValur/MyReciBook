// ChannelHttpClient against a mocked net channel: the bridge reply becomes a
// normal http.Response, bridge failures become ClientExceptions, and the
// whole thing composes with LinkExtractor's transport mapping. The Kotlin
// side (NetBridge) is NOT covered here — only the S21 proves that.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/link_extractor.dart';
import 'package:myrecibook/data/link_fetch_client.dart';
import 'package:myrecibook/domain/extractor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('fake-net-test');

  void mock(Future<Object?> Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('bridge reply flows through LinkExtractor to parsed content', () async {
    const url = 'https://example.com/buns';
    mock((call) async {
      expect(call.method, 'get');
      expect(call.arguments['url'], url);
      expect(call.arguments['headers']['User-Agent'], contains('Mozilla'));
      return {
        'status': 200,
        'body': utf8.encode('<script type="application/ld+json">'
            '{"@type":"Recipe","name":"Buns",'
            '"recipeIngredient":["flour","yeast"],'
            '"recipeInstructions":"Bake."}</script>'),
      };
    });
    final extractor =
        LinkExtractor(url: url, client: ChannelHttpClient(channel: channel));
    final content = await extractor.extractContent(const <File>[]);
    expect(content['title'], 'Buns');
    expect((content['source'] as Map)['type'], 'link');
  });

  test('bridge io error surfaces as offline, not a crash', () async {
    mock((call) async =>
        throw PlatformException(code: 'io', message: 'java.net.UnknownHostException: no internet'));
    final extractor = LinkExtractor(
        url: 'https://example.com/x',
        client: ChannelHttpClient(channel: channel));
    expect(
        () => extractor.extractContent(const <File>[]),
        throwsA(isA<ExtractionException>()
            .having((e) => e.message, 'message', startsWith('offline'))));
  });

  test('non-200 status from the bridge keeps its status code', () async {
    mock((call) async => {'status': 403, 'body': utf8.encode('blocked')});
    final extractor = LinkExtractor(
        url: 'https://example.com/x',
        client: ChannelHttpClient(channel: channel));
    expect(
        () => extractor.extractContent(const <File>[]),
        throwsA(isA<ExtractionException>()
            .having((e) => e.httpStatus, 'httpStatus', 403)));
  });

  test('malformed bridge reply is a ClientException, not a type error',
      () async {
    mock((call) async => {'status': 'weird'});
    final extractor = LinkExtractor(
        url: 'https://example.com/x',
        client: ChannelHttpClient(channel: channel));
    expect(
        () => extractor.extractContent(const <File>[]),
        throwsA(isA<ExtractionException>().having(
            (e) => e.message, 'message', contains('malformed bridge reply'))));
  });
}
