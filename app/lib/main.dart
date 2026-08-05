import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'data/gemini_extractor.dart';
import 'data/recipe_store.dart';
import 'domain/extractor.dart';
import 'ui/library_model.dart';
import 'ui/recipe_list_screen.dart';

typedef ImagePick = Future<List<File>> Function();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final docs = await getApplicationDocumentsDirectory();
  final picker = ImagePicker();
  runApp(buildApp(
    store: LocalFolderStore(Directory('${docs.path}/recipes')),
    extractor: GeminiExtractor(),
    picker: () async =>
        [for (final x in await picker.pickMultiImage()) File(x.path)],
  ));
}

/// Widget-test seam: everything platform-bound is injected.
Widget buildApp({
  required RecipeStore store,
  required Extractor extractor,
  required ImagePick picker,
}) =>
    ChangeNotifierProvider(
      create: (_) => LibraryModel(store),
      child: MaterialApp(
        title: 'MyReciBook',
        home: RecipeListScreen(extractor: extractor, picker: picker),
      ),
    );
