import 'dart:io';

import 'package:flutter/foundation.dart' show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'data/app_settings.dart';
import 'data/gemini_extractor.dart';
import 'data/grocery_store.dart';
import 'data/recipe_store.dart';
import 'data/share_entry.dart';
import 'data/share_intake.dart';
import 'domain/extractor.dart';
import 'ui/app_shell.dart';
import 'ui/folder_gate.dart';
import 'ui/grocery_model.dart';
import 'ui/library_model.dart';
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
  final support = await getApplicationSupportDirectory();
  final cache = await getApplicationCacheDirectory();
  final settings = await AppSettings.load(File('${support.path}/settings.json'));
  // Grocery is app-private working state (T3) — app-support, not the SAF folder.
  final grocery = await GroceryStore.load(
      listFile: File('${support.path}/grocery_list.json'),
      overridesFile: File('${support.path}/grocery_overrides.json'));

  // Constructed once, before takePending; warm shares buffer in the entry
  // until the gate resolves (bridge contract + arch §3.1).
  final intake = ShareIntake();
  final share = ShareEntry(takePending: intake.takePending);
  intake.onShared = share.push;

  final picker = ImagePicker();
  final extractor = GeminiExtractor();
  Future<List<File>> pickImages() async =>
      [for (final x in await picker.pickMultiImage()) File(x.path)];
  Future<List<File>> snapPage() async {
    final x = await picker.pickImage(source: ImageSource.camera);
    return x == null ? const <File>[] : [File(x.path)];
  }

  runApp(BootGate(
    settings: settings,
    localStore: LocalFolderStore(Directory('${docs.path}/recipes')),
    imageCache: Directory('${cache.path}/saf_images'),
    appBuilder: (store, onGrantLost, onChangeFolder) => buildApp(
      store: store,
      extractor: extractor,
      picker: pickImages,
      camera: snapPage,
      share: share,
      grocery: grocery,
      onGrantLost: onGrantLost,
      onChangeFolder: onChangeFolder,
      folderName: folderDisplayName(settings.treeUri),
    ),
  ));
}

/// Widget-test seam: everything platform-bound is injected.
Widget buildApp({
  required RecipeStore store,
  required Extractor extractor,
  required ImagePick picker,
  ImagePick? camera,
  ShareEntry? share,
  GroceryStore? grocery,
  VoidCallback? onGrantLost,
  VoidCallback? onChangeFolder,
  String? folderName,
}) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => LibraryModel(store, onGrantLost: onGrantLost)),
        // Shell AND pushed routes (detail's grocery button) share this scope.
        ChangeNotifierProvider(create: (_) => GroceryModel(grocery)),
      ],
      child: MaterialApp(
        title: 'MyReciBook',
        theme: rbLightTheme(),
        darkTheme: rbDarkTheme(),
        home: AppShell(
          extractor: extractor,
          picker: picker,
          camera: camera,
          share: share,
          folderName: folderName,
          onChangeFolder: onChangeFolder,
        ),
      ),
    );
