import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show LicenseRegistry, LicenseEntryWithLineBreaks;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'data/app_settings.dart';
import 'data/crash_log.dart';
import 'data/gemini_extractor.dart';
import 'data/grocery_store.dart';
import 'data/install_id.dart';
import 'data/oauth.dart';
import 'data/recipe_store.dart';
import 'data/sha256.dart';
import 'data/share_entry.dart';
import 'data/share_intake.dart';
import 'data/sync_engine.dart';
import 'data/sync_source.dart';
import 'data/token_store.dart';
import 'domain/extractor.dart';
import 'ui/app_shell.dart';
import 'ui/batch_model.dart';
import 'ui/folder_gate.dart';
import 'ui/grocery_model.dart';
import 'ui/library_model.dart';
import 'ui/storage_model.dart';
import 'ui/theme.dart';
import 'ui/theme_model.dart';

typedef ImagePick = Future<List<File>> Function();

// Storage connector credentials (rule 6): device builds read the gitignored
// app/dev.env via --dart-define-from-file — it gains DRIVE_CLIENT_ID=... and
// DROPBOX_APP_KEY=... when Arnar's Google/Dropbox registrations land. Until
// then the placeholders keep the connectors in the honest unconfigured state.
const _driveClientId =
    String.fromEnvironment('DRIVE_CLIENT_ID', defaultValue: 'placeholder-drive');
const _dropboxAppKey = String.fromEnvironment('DROPBOX_APP_KEY',
    defaultValue: 'placeholder-dropbox');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Fonts are bundled assets (pubspec google_fonts/); with runtime fetching
  // off a missed lookup falls back locally instead of trying the network.
  GoogleFonts.config.allowRuntimeFetching = false;
  // Bundled-font licenses (OFL) surface in the standard licenses page.
  LicenseRegistry.addLicense(() async* {
    for (final f in ['OFL-PlusJakartaSans.txt', 'OFL-Inter.txt']) {
      yield LicenseEntryWithLineBreaks(
          ['google_fonts'], await rootBundle.loadString('google_fonts/$f'));
    }
  });
  // Two parallel batches instead of seven serial awaits — every one of these
  // gates the first frame (review 2026-08-09).
  final (docs, support, cache) = await (
    getApplicationDocumentsDirectory(),
    getApplicationSupportDirectory(),
    getApplicationCacheDirectory(),
  ).wait;
  // Grocery is app-private working state (T3) — app-support, not the SAF folder.
  final (settings, crashLog, grocery, tokenStore, installId) = await (
    AppSettings.load(File('${support.path}/settings.json')),
    CrashLog.load(File('${support.path}/crash_log.json')),
    GroceryStore.load(
        listFile: File('${support.path}/grocery_list.json'),
        overridesFile: File('${support.path}/grocery_overrides.json')),
    TokenStore.load(File('${support.path}/tokens.json')),
    loadInstallId(File('${support.path}/install_id')),
  ).wait;

  // Uncaught errors → local ring-buffer (crash story without telemetry, D8).
  // Both hooks log and move on: for a consumer app a degraded frame beats a
  // process death, and the evidence survives for the tester to copy out.
  FlutterError.onError = (details) {
    FlutterError.presentError(details); // keep the default console dump
    String? context;
    try {
      context = details.context?.toDescription();
    } catch (_) {} // a throwing DiagnosticsNode must not break the hook
    crashLog.record(details.exception, details.stack, context: context);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    // Keep logcat visibility — recording alone would make async failures
    // invisible outside the long-press door during development.
    debugPrint('Uncaught async error: $error\n$stack');
    crashLog.record(error, stack);
    // Trade-off, eyes open: true keeps the app alive but also keeps these
    // out of Play Console vitals. During closed test the local log IS the
    // crash story; revisit for production if vitals ever matter.
    return true; // handled: logged locally
  };
  // THE one OAuthFlow app-wide — its constructor claims the auth channel
  // handler; a second instance would silently steal redirects.
  final oauthFlow = OAuthFlow();
  final storage = StorageModel(
    settings: settings,
    tokenStore: tokenStore,
    flow: oauthFlow,
    driveClientId: _driveClientId,
    dropboxAppKey: _dropboxAppKey,
    engineFactory: (remote, onStatus) {
      // Reads the live treeUri per pass so a re-picked folder is mirrored
      // through a fresh source, never a stale one.
      final uri = settings.treeUri;
      if (uri == null) return null; // no folder picked — nothing to mirror
      // Manifest per folder: a switched folder must not inherit the old
      // folder's landed names (they'd read as vanished → remote deletes).
      final key = _hexPrefix(sha256(utf8.encode(uri)));
      return SyncEngine(
        source: SafFolderSource(treeUri: uri),
        remote: remote,
        manifestFile: File('${support.path}/sync_manifest_$key.json'),
        onStatus: onStatus,
      );
    },
  );
  storage.syncSoon(); // boot pass when a connector is already active

  // Constructed once, before takePending; warm shares buffer in the entry
  // until the gate resolves (bridge contract + arch §3.1).
  final intake = ShareIntake();
  final share = ShareEntry(takePending: intake.takePending);
  intake.onShared = share.push;

  // App-lifetime like storage: outlives BootGate re-entries, so buildApp
  // providers it with .value and never disposes it.
  final themeModel = ThemeModel(settings: settings);

  final picker = ImagePicker();
  final extractor = GeminiExtractor(installId: installId);
  Future<List<File>> pickImages() async =>
      [for (final x in await picker.pickMultiImage()) File(x.path)];
  Future<List<File>> snapPage() async {
    final x = await picker.pickImage(source: ImageSource.camera);
    return x == null ? const <File>[] : [File(x.path)];
  }

  // One navigator key across the gate's and the app's MaterialApps (never
  // mounted together): the change-folder confirm dialog needs a navigator
  // while the app is still up, now that a deliberate change skips the gate.
  final nav = GlobalKey<NavigatorState>();

  runApp(BootGate(
    settings: settings,
    localStore: LocalFolderStore(Directory('${docs.path}/recipes')),
    imageCache: Directory('${cache.path}/saf_images'),
    // The gate's own MaterialApp follows the saved preference — without this
    // it sat on ThemeMode.system and change-folder opened dark over a light
    // app (Arnar's S21 pass, 2026-08-06).
    themeMode: themeModel,
    appNavigatorKey: nav,
    appBuilder: (store, onGrantLost, onChangeFolder) {
      // A lost grant mid-sync joins the same re-pick flow as store ops.
      storage.onGrantLost = onGrantLost;
      return buildApp(
        store: store,
        extractor: extractor,
        picker: pickImages,
        camera: snapPage,
        share: share,
        grocery: grocery,
        storage: storage,
        themeModel: themeModel,
        crashLog: crashLog,
        onGrantLost: onGrantLost,
        onChangeFolder: onChangeFolder,
        folderName: folderDisplayName(settings.treeUri),
        navigatorKey: nav,
      );
    },
  ));
}

String _hexPrefix(List<int> bytes) =>
    [for (final b in bytes.take(8)) b.toRadixString(16).padLeft(2, '0')].join();

/// Widget-test seam: everything platform-bound is injected. [storage] is the
/// app-lifetime connector model; omitted (tests) it defaults to an inert
/// instance — old behavior, honest 'This phone' states, no sync.
Widget buildApp({
  required RecipeStore store,
  required Extractor extractor,
  required ImagePick picker,
  ImagePick? camera,
  ShareEntry? share,
  GroceryStore? grocery,
  StorageModel? storage,
  ThemeModel? themeModel,
  CrashLog? crashLog,
  VoidCallback? onGrantLost,
  VoidCallback? onChangeFolder,
  String? folderName,
  GlobalKey<NavigatorState>? navigatorKey,
}) =>
    MultiProvider(
      providers: [
        // .value for the injected instance: it outlives gate re-entries
        // (BootGate rebuilds this subtree), so the provider must not dispose it.
        if (storage != null)
          ChangeNotifierProvider<StorageModel>.value(value: storage)
        else
          ChangeNotifierProvider<StorageModel>(create: (_) => StorageModel()),
        // Same .value rule; the inert default is stuck on ThemeMode.system —
        // the exact pre-settings behavior, so the test seam stays unchanged.
        if (themeModel != null)
          ChangeNotifierProvider<ThemeModel>.value(value: themeModel)
        else
          ChangeNotifierProvider<ThemeModel>(create: (_) => ThemeModel()),
        // Plain Provider (not a notifier): the settings footer door reads it
        // on demand. Inert default keeps the test seam file-free.
        Provider<CrashLog>.value(value: crashLog ?? CrashLog.inert()),
        ChangeNotifierProvider(
            create: (ctx) => LibraryModel(store,
                onGrantLost: onGrantLost,
                // Main-level glue: library mutations schedule the debounced
                // connector sync; LibraryModel never sees StorageModel.
                onChanged:
                    Provider.of<StorageModel>(ctx, listen: false).syncSoon)),
        // Shell AND pushed routes (detail's grocery button) share this scope.
        ChangeNotifierProvider(create: (_) => GroceryModel(grocery)),
        // Session batch queue (D5): lives above the shell so it survives tab
        // switches and pushed routes; dies with the app. Saves ride the
        // LibraryModel seam, so grocery/storage glue comes along for free.
        ChangeNotifierProvider(
            create: (ctx) => BatchModel(
                extractor: extractor,
                save: (recipe, images) =>
                    ctx.read<LibraryModel>().saveImported(recipe, images))),
      ],
      // Consumer, not a plain read: MaterialApp.themeMode must react live
      // when the settings tab changes the preference.
      child: Consumer<ThemeModel>(
        builder: (_, themeModel, child) => MaterialApp(
          title: 'MyReciBook',
          navigatorKey: navigatorKey,
          theme: rbLightTheme(),
          darkTheme: rbDarkTheme(),
          themeMode: themeModel.mode,
          home: AppShell(
            extractor: extractor,
            picker: picker,
            camera: camera,
            share: share,
            folderName: folderName,
            onChangeFolder: onChangeFolder,
          ),
        ),
      ),
    );
