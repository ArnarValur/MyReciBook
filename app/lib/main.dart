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

import 'data/app_check.dart';
import 'data/app_settings.dart';
import 'data/crash_log.dart';
import 'data/crash_reporter.dart';
import 'data/crashlytics_sink.dart';
import 'data/diary_store.dart';
import 'data/gemini_extractor.dart';
import 'data/grocery_store.dart';
import 'data/install_id.dart';
import 'data/oauth.dart';
import 'data/product_store.dart';
import 'data/recipe_store.dart';
import 'data/saf_diary_store.dart';
import 'data/sha256.dart';
import 'data/share_entry.dart';
import 'data/share_intake.dart';
import 'data/sync_engine.dart';
import 'data/sync_source.dart';
import 'data/token_store.dart';
import 'domain/app_language.dart';
import 'domain/extractor.dart';
import 'ui/app_shell.dart';
import 'ui/batch_model.dart';
import 'ui/cookbook_prefs.dart';
import 'ui/crash_reporting_model.dart';
import 'ui/units_model.dart';
import 'ui/language_model.dart';
import 'ui/folder_gate.dart';
import 'ui/grocery_model.dart';
import 'ui/library_model.dart';
import 'ui/diary/diary_model.dart';
import 'ui/pantry/pantry_model.dart';
import 'ui/storage_model.dart';
import 'ui/photo_sources.dart';
import 'ui/theme.dart';
import 'ui/theme_model.dart';
import 'l10n/generated/app_localizations.dart';

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

  // Uncaught errors → the reporter, which records locally ALWAYS and uploads
  // only when the user has crash reporting on (crash_reporter.dart).
  // Nothing is swallowed any more: an invisible crash is a crash nobody ever
  // fixes, and we are about to have users who are not Arnar (audit H1).
  final crashReporter = CrashReporter(
    log: crashLog,
    sink: await buildCrashSink(),
    enabled: settings.crashReportingEnabled,
  );
  FlutterError.onError = (details) {
    String? context;
    try {
      context = details.context?.toDescription();
    } catch (_) {} // a throwing DiagnosticsNode must not break the hook
    crashReporter.record(details.exception, details.stack, context: context);
    FlutterError.presentError(details); // the framework's own dump, unchanged
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    crashReporter.record(error, stack);
    // false = NOT handled. The error carries on to the VM's default handler
    // and into logcat instead of stopping here. Note the honest limit: this
    // alone does not put a Dart error into Play vitals — Flutter does not
    // kill the process for one — the Crashlytics sink is what makes a crash
    // visible off-device. Both layers, neither sufficient alone.
    return false;
  };
  final crashReporting =
      CrashReportingModel(settings: settings, reporter: crashReporter);

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
  final share = ShareEntry(
      takePending: intake.takePending,
      takePendingLinks: intake.takePendingLinks);
  intake.onShared = share.push;
  intake.onSharedLink = share.pushLink;

  // App-lifetime like storage: outlives BootGate re-entries, so buildApp
  // providers it with .value and never disposes it.
  final themeModel = ThemeModel(settings: settings);
  final cookbookPrefs = CookbookPrefs(settings: settings);
  final unitsModel = UnitsModel(settings: settings);
  final languageModel = LanguageModel(settings: settings);

  final picker = ImagePicker();
  // App Check proves to the proxy that this really is our app on a real
  // device (audit B1). Null in any build without Firebase — the header is
  // then absent, which the proxy accepts only while it runs unenforced.
  final appCheck = await AppCheckTokens.activate();
  final extractor = GeminiExtractor(
    installId: installId,
    appCheckToken: appCheck?.token,
  );
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
    // Pre-pantry installs kept products app-private here; BootGate drains it
    // into <tree>/pantry/ (copy-verify-delete) so pantry data lives and syncs
    // beside the recipes from now on.
    localPantry: LocalPantryStore(Directory('${docs.path}/pantry')),
    imageCache: Directory('${cache.path}/saf_images'),
    pantryImageCache: Directory('${cache.path}/pantry_images'),
    // The gate's own MaterialApp follows the saved preference — without this
    // it sat on ThemeMode.system and change-folder opened dark over a light
    // app (Arnar's S21 pass, 2026-08-06).
    themeMode: themeModel,
    // Same reason as themeMode: the gate's own MaterialApp is built before the
    // provider tree, so it needs the language handed to it directly.
    locale: languageModel,
    appNavigatorKey: nav,
    // The first-run setup screen writes through the app-lifetime models, so
    // the choice reaches every listener at once instead of on next boot.
    units: unitsModel,
    onUnits: unitsModel.setSystem,
    onThemeMode: themeModel.setMode,
    appBuilder: (store, pantry, onGrantLost, onChangeFolder) {
      // A lost grant mid-sync joins the same re-pick flow as store ops.
      storage.onGrantLost = onGrantLost;
      return buildApp(
        store: store,
        extractor: extractor,
        picker: pickImages,
        camera: snapPage,
        share: share,
        grocery: grocery,
        // Pantry lives in the user's tree (<tree>/pantry/) via the SAF store
        // BootGate built beside the recipe store, and the sync layout's
        // pantry/ case mirrors it like everything else.
        pantry: pantry,
        // Same tree as the recipes and the pantry: <tree>/diary/.
        diary: SafDiaryStore(treeUri: store.treeUri),
        settings: settings,
        storage: storage,
        themeModel: themeModel,
        cookbookPrefs: cookbookPrefs,
        unitsModel: unitsModel,
        languageModel: languageModel,
        crashLog: crashLog,
        crashReporting: crashReporting,
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
  Extractor Function(String url)? linkExtractor,
  GroceryStore? grocery,
  ProductStore? pantry,
  DiaryStore? diary,
  AppSettings? settings,
  StorageModel? storage,
  ThemeModel? themeModel,
  CookbookPrefs? cookbookPrefs,
  UnitsModel? unitsModel,
  LanguageModel? languageModel,
  CrashLog? crashLog,
  CrashReportingModel? crashReporting,
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
        // Same .value rule; the inert default is stuck on grid — the exact
        // pre-toggle behavior, so the test seam stays unchanged.
        if (cookbookPrefs != null)
          ChangeNotifierProvider<CookbookPrefs>.value(value: cookbookPrefs)
        else
          ChangeNotifierProvider<CookbookPrefs>(create: (_) => CookbookPrefs()),
        // Same .value rule; the inert default is stuck on as-written — the
        // exact pre-toggle behavior, so the test seam stays unchanged.
        if (unitsModel != null)
          ChangeNotifierProvider<UnitsModel>.value(value: unitsModel)
        else
          ChangeNotifierProvider<UnitsModel>(create: (_) => UnitsModel()),
        // Same .value rule; the inert default follows the phone's language —
        // the exact pre-toggle behavior, so the test seam stays unchanged.
        if (languageModel != null)
          ChangeNotifierProvider<LanguageModel>.value(value: languageModel)
        else
          ChangeNotifierProvider<LanguageModel>(
              create: (_) => LanguageModel()),
        // Plain Provider (not a notifier): the settings footer door reads it
        // on demand. Inert default keeps the test seam file-free.
        Provider<CrashLog>.value(value: crashLog ?? CrashLog.inert()),
        // Same .value rule as the models above; the inert default has no
        // settings and no reporter, so it reads the compiled-in default and
        // reports no sink — the Settings row then renders its "not available
        // in this build" state, which is exactly right for tests.
        if (crashReporting != null)
          ChangeNotifierProvider<CrashReportingModel>.value(
              value: crashReporting)
        else
          ChangeNotifierProvider<CrashReportingModel>(
              create: (_) => CrashReportingModel()),
        // Same stance: the cover picker on the pushed detail route reads these
        // on demand instead of being threaded down through list and card.
        Provider<PhotoSources>.value(
            value: PhotoSources(gallery: picker, camera: camera)),
        ChangeNotifierProvider(
            create: (ctx) => LibraryModel(store,
                onGrantLost: onGrantLost,
                // Main-level glue: library mutations schedule the debounced
                // connector sync; LibraryModel never sees StorageModel.
                onChanged:
                    Provider.of<StorageModel>(ctx, listen: false).syncSoon)),
        // Shell AND pushed routes (detail's grocery button) share this scope.
        ChangeNotifierProvider(create: (_) => GroceryModel(grocery)),
        // Same stance for the pantry POC: null store (test seam) degrades to
        // in-memory; the real OffClient only fires on an actual scan.
        ChangeNotifierProvider(create: (_) => PantryModel(pantry)),
        // The diary reads and writes one day file at a time; a null store
        // (widget-test seam, or a build with no folder picked) degrades to
        // in-memory exactly like the pantry does.
        ChangeNotifierProvider(
            create: (_) => DiaryModel(diary, settings: settings)),
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
      // Consumer2, not a plain read: MaterialApp.themeMode and .locale must
      // both react live when the settings tab changes a preference.
      child: Consumer2<ThemeModel, LanguageModel>(
        builder: (_, themeModel, languageModel, child) => MaterialApp(
          title: 'MyReciBook',
          navigatorKey: navigatorKey,
          theme: rbLightTheme(),
          darkTheme: rbDarkTheme(),
          themeMode: themeModel.mode,
          // null = follow the phone; MaterialApp then matches the device
          // language against supportedLocales itself.
          locale: languageModel.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kOfferedLocales,
          home: AppShell(
            extractor: extractor,
            picker: picker,
            camera: camera,
            share: share,
            linkExtractor: linkExtractor,
            folderName: folderName,
            onChangeFolder: onChangeFolder,
          ),
        ),
      ),
    );
