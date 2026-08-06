// Test-wide config: fonts must come from the bundled google_fonts/ assets —
// a network fetch inside the test zone rethrows and fails whatever test
// happens to be pumping (google_fonts loadFontIfNecessary contract).

import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
