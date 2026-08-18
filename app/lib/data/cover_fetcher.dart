// Downloads a link import's hero photo and shrinks it to cover size
// (share-links spike). Covers show at most full-screen width, so anything
// beyond 1080px on the long side is wasted bytes in the user's folder —
// decode/resize/re-encode runs in an isolate to keep the review screen
// smooth. A cover is a nice-to-have: every failure returns null, never
// an error surface.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CoverFetcher {
  CoverFetcher({required this.client, this.maxBytes = 15 * 1024 * 1024});

  final http.Client client;
  final int maxBytes;

  static const _userAgent = 'Mozilla/5.0 (Linux; Android 13; SM-G991B) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Mobile Safari/537.36';

  Future<File?> fetch(String url) async {
    try {
      final resp = await client.get(Uri.parse(url), headers: {
        'User-Agent': _userAgent,
        'Accept': 'image/*',
      }).timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
      if (resp.bodyBytes.length > maxBytes) return null;
      final jpg = await compute(shrinkToCover, resp.bodyBytes);
      if (jpg == null) return null;
      final dir = Directory(
          '${(await getApplicationCacheDirectory()).path}/link_covers');
      await dir.create(recursive: true);
      final out = File(
          '${dir.path}/cover-${DateTime.now().microsecondsSinceEpoch}.jpg');
      await out.writeAsBytes(jpg);
      return out;
    } catch (_) {
      return null;
    }
  }
}

/// Isolate worker: decode anything package:image reads (jpg/png/webp/gif),
/// cap the long side at 1080px, re-encode as JPEG q80. Null on undecodable
/// bytes (svg, html error pages served as images…).
Uint8List? shrinkToCover(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    const maxDim = 1080;
    final longSide =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longSide <= maxDim
        ? decoded
        : (decoded.width >= decoded.height
            ? img.copyResize(decoded,
                width: maxDim, interpolation: img.Interpolation.linear)
            : img.copyResize(decoded,
                height: maxDim, interpolation: img.Interpolation.linear));
    return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
  } catch (_) {
    return null;
  }
}
