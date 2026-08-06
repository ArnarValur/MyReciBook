import 'dart:io';

import 'package:flutter/foundation.dart' show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'data/gemini_extractor.dart';
import 'data/recipe_store.dart';
import 'domain/extractor.dart';
import 'ui/library_model.dart';
import 'ui/recipe_list_screen.dart';
import 'ui/theme.dart';

typedef ImagePick = Future<List<File>> Function();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Bundled-font licenses (OFL) surface in the standard licenses page.
  LicenseRegistry.addLicense(() async* {
    for (final f in ['OFL-PlusJakartaSans.txt', 'OFL-Inter.txt']) {
      yield LicenseEntryWithLineBreaks(
          ['google_fonts'], await rootBundle.loadString('google_fonts/$f'));
    }
  });
  final docs = await getApplicationDocumentsDirectory();
  final picker = ImagePicker();
  runApp(buildApp(
    store: LocalFolderStore(Directory('${docs.path}/recipes')),
    extractor: GeminiExtractor(),
    picker: () async =>
        [for (final x in await picker.pickMultiImage()) File(x.path)],
    camera: () async {
      final x = await picker.pickImage(source: ImageSource.camera);
      return x == null ? const <File>[] : [File(x.path)];
    },
  ));
}

/// Widget-test seam: everything platform-bound is injected.
Widget buildApp({
  required RecipeStore store,
  required Extractor extractor,
  required ImagePick picker,
  ImagePick? camera,
}) =>
    ChangeNotifierProvider(
      create: (_) => LibraryModel(store),
      child: MaterialApp(
        title: 'MyReciBook',
        theme: rbLightTheme(),
        darkTheme: rbDarkTheme(),
        home: RecipeListScreen(
            extractor: extractor, picker: picker, camera: camera),
      ),
    );
