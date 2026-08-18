// Link-import cover toggle (share-links spike): the site's photo shows as a
// toggle row, defaults ON, saves through the store's cover seam, and stays
// out of the file when toggled off. shrinkToCover and imageUrlFromJsonLd are
// covered as pure functions.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:myrecibook/data/cover_fetcher.dart';
import 'package:myrecibook/data/link_extractor.dart';
import 'package:myrecibook/data/recipe_store.dart';
import 'package:myrecibook/domain/extractor.dart';
import 'package:myrecibook/ui/import_review_screen.dart';
import 'package:myrecibook/ui/library_model.dart';
import 'package:myrecibook/ui/theme.dart';
import 'package:provider/provider.dart';

class _NoExtractor implements Extractor {
  @override
  String get mode => 'link';
  @override
  String get modelName => 'jsonld';
  @override
  Future<Map<String, dynamic>> extractContent(List<File> images) =>
      throw StateError('prefilled review must not extract');
}

void main() {
  group('shrinkToCover', () {
    test('caps the long side at 1080 and re-encodes as jpg', () {
      final wide = img.Image(width: 2000, height: 1000);
      final out = shrinkToCover(Uint8List.fromList(img.encodePng(wide)))!;
      final decoded = img.decodeJpg(out)!;
      expect(decoded.width, 1080);
      expect(decoded.height, 540);

      final tall = img.Image(width: 500, height: 1600);
      final outTall = shrinkToCover(Uint8List.fromList(img.encodePng(tall)))!;
      final decodedTall = img.decodeJpg(outTall)!;
      expect(decodedTall.height, 1080);
    });

    test('small images pass through unscaled; garbage returns null', () {
      final small = img.Image(width: 300, height: 200);
      final out = shrinkToCover(Uint8List.fromList(img.encodePng(small)))!;
      expect(img.decodeJpg(out)!.width, 300);
      expect(shrinkToCover(Uint8List.fromList(utf8.encode('<html>nope'))),
          isNull);
    });
  });

  group('imageUrlFromJsonLd', () {
    test('reads string, list and ImageObject shapes', () {
      expect(imageUrlFromJsonLd('https://x.com/a.jpg'), 'https://x.com/a.jpg');
      expect(imageUrlFromJsonLd(['https://x.com/b.jpg', 'https://x.com/c.jpg']),
          'https://x.com/b.jpg');
      expect(
          imageUrlFromJsonLd(
              {'@type': 'ImageObject', 'url': 'https://x.com/d.jpg'}),
          'https://x.com/d.jpg');
      expect(
          imageUrlFromJsonLd([
            {'contentUrl': 'https://x.com/e.jpg'}
          ]),
          'https://x.com/e.jpg');
      expect(imageUrlFromJsonLd('not-a-url'), isNull);
      expect(imageUrlFromJsonLd(null), isNull);
    });
  });

  group('cover toggle in review', () {
    late Directory tmp;
    // Real IO (image decode, store writes) never completes under the fake
    // test clock — bounded runAsync rounds instead of pumpAndSettle, the
    // shell_test harness discipline.
    Future<void> settle(WidgetTester tester, {int rounds = 12}) async {
      for (var i = 0; i < rounds; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    late LocalFolderStore store;
    late File hero;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('recibook_link_cover');
      store = LocalFolderStore(Directory('${tmp.path}/recipes'));
      // A real decodable jpg — Image.file renders it in the row.
      hero = File('${tmp.path}/hero.jpg');
      await hero.writeAsBytes(
          img.encodeJpg(img.Image(width: 40, height: 40), quality: 80));
    });

    tearDown(() => tmp.delete(recursive: true));

    Map<String, dynamic> linkContent() => {
          'image_url': 'https://example.com/hero.jpg',
          'title': 'Buns',
          'source': {'type': 'link', 'url': 'https://example.com/buns'},
          'ingredients': [
            {'raw': 'flour', 'confidence': 1.0},
            {'raw': 'yeast', 'confidence': 1.0},
          ],
          'steps': [
            {'raw': 'Bake.', 'confidence': 1.0},
          ],
          'extraction': {'overall_confidence': 1.0, 'needs_review': <String>[]},
        };

    Widget harness({required Future<File?> Function(String) fetchCover}) =>
        ChangeNotifierProvider(
          create: (_) => LibraryModel(store),
          child: MaterialApp(
            theme: rbLightTheme(),
            home: ImportReviewScreen.prefilled(
              images: const [],
              content: linkContent(),
              extractor: _NoExtractor(),
              pickMore: () async => const [],
              fetchCover: fetchCover,
            ),
          ),
        );

    testWidgets('toggle on (default) saves the photo as cover',
        (tester) async {
      String? fetched;
      await tester.pumpWidget(harness(fetchCover: (url) async {
        fetched = url;
        return hero;
      }));
      await settle(tester);

      expect(fetched, 'https://example.com/hero.jpg');
      expect(find.text('Use their photo as the cover'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);

      await tester.tap(find.text('Save to cookbook'));
      await settle(tester, rounds: 60);

      final saved =
          (await tester.runAsync(() => store.listAll()))!.recipes.single;
      expect(saved.cover, 'images/${saved.id}-cover.jpg');
      // The envelope must keep where it came from (source.url round-trip).
      expect(saved.source.url, 'https://example.com/buns');
      expect(
          File('${tmp.path}/recipes/${saved.cover}').existsSync(), isTrue);
    });

    testWidgets('toggle off keeps the cover out of the file', (tester) async {
      await tester.pumpWidget(harness(fetchCover: (_) async => hero));
      await settle(tester);

      await tester.tap(find.byType(Switch));
      await tester.pump();
      await tester.tap(find.text('Save to cookbook'));
      await settle(tester, rounds: 60);

      final saved =
          (await tester.runAsync(() => store.listAll()))!.recipes.single;
      expect(saved.cover, isNull);
    });

    testWidgets('failed download hides the row entirely', (tester) async {
      await tester.pumpWidget(harness(fetchCover: (_) async => null));
      await settle(tester, rounds: 4);
      expect(find.byType(Switch), findsNothing);
    });
  });
}
