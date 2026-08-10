// The two ways a user hands the app a picture, provided app-wide so pushed
// routes can reach them without threading callbacks through every widget
// between the shell and the screen (same stance as Provider<CrashLog>).
//
// Import already had these injected at main(); the cover picker on the detail
// screen is the second caller, three pushes deep.

import 'dart:io';

typedef ImagePick = Future<List<File>> Function();

class PhotoSources {
  const PhotoSources({required this.gallery, this.camera});

  /// System photo picker. Returns empty when the user backs out.
  final ImagePick gallery;

  /// Camera capture — null on builds/tests without one.
  final ImagePick? camera;

  /// First image only, for callers that want exactly one (covers).
  Future<File?> pickOne(ImagePick source) async {
    final picked = await source();
    return picked.isEmpty ? null : picked.first;
  }
}
