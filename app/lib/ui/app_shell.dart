// App shell — the promoted turn-4 nav: glass pill bar with the gradient FAB
// as the import door. Lives only inside BootGate's ready phase; gate and
// migration stay shell-less. The shell owns the ShareEntry attach point and
// the import flow so shares land in review from any tab; pushed routes cover
// the bar.
//
// DEVIATION (Arnar's hands-on pass, 2026-08-06 — for Design to ratify in
// turn 7): slot 3 of the bar was Meal plan; it is now Import queue (Meal plan
// had no engine; the queue is the batch-rescue surface the pitch is built
// on). The 5c DRAWER IS REMOVED ENTIRELY — after the dead-end rule hid its
// engine-less rows (Your copy, Help & feedback) everything left duplicated
// the bar or Settings, and a founder-decision (Arnar + Code agreeing) cut
// the maintenance surface. Its future rows (Your copy at billing 3g, Help)
// land as Settings rows instead.
//
// SUPERSEDED 2026-08-15 (Arnar, settling the turn-7 question himself): the
// Queue TAB retires — "kinda useless, I never use it" — and slot 2 sells the
// app instead (unlock_tab.dart, behind kUnlockTabEnabled). Batch imports
// still push the queue screen, and the Cookbook attention strip + Cookbook
// badge are the way back to a queue that still wants eyes.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:provider/provider.dart';

import '../features.dart';

import '../data/cover_fetcher.dart';
import '../data/gemini_extractor.dart';
import '../data/link_extractor.dart';
import '../data/link_fetch_client.dart';
import '../data/share_entry.dart';
import '../domain/extractor.dart';
import 'batch_model.dart';
import 'batch_queue_screen.dart';
import 'diary/food_tab.dart';
import 'grocery_tab.dart';
import 'import_review_screen.dart';
import 'import_sheet.dart';
import 'manual_entry_screen.dart';
import 'library_model.dart';
import 'pantry/pantry_tab.dart';
import 'plan_tab.dart';
import 'recipe_list_screen.dart';
import 'settings_tab.dart';
import 'storage_screen.dart';
import 'unlock_tab.dart';
import 'widgets/glass_nav_bar.dart';

/// Display form of a SAF tree uri — the folder name the user picked.
String? folderDisplayName(String? treeUri) {
  if (treeUri == null) return null;
  final segs = Uri.parse(treeUri).pathSegments;
  if (segs.isEmpty) return null;
  final name = segs.last.split(':').last.split('/').last.trim();
  return name.isEmpty ? segs.last : name;
}

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.extractor,
    required this.picker,
    this.camera,
    this.share,
    this.folderName,
    this.onChangeFolder,
    this.linkExtractor,
  });

  final Extractor extractor;
  final Future<List<File>> Function() picker;

  /// Optional "Snap a page" source; the sheet hides the row when absent.
  final Future<List<File>> Function()? camera;

  /// Share-sheet arrivals enter the same review flow as picked images.
  final ShareEntry? share;

  /// Display name of the picked recipes folder (drawer Storage row).
  final String? folderName;

  /// Deliberate folder change — routes to the existing BootGate re-pick flow.
  final VoidCallback? onChangeFolder;

  /// Test seam (share-links spike): builds the extractor for a shared URL.
  /// Null = the real LinkExtractor.
  final Extractor Function(String url)? linkExtractor;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  // Lazy tabs: a surface is built on first visit and then kept alive, so
  // finders and IO stay quiet until a tester actually goes there.
  // Index 2 is Unlock (queue tab retired 2026-08-15 — see above).
  final List<bool> _built = [true, false, false, false];

  bool _importBusy = false;

  // Shares arriving while an import is open wait here — hijacking an open
  // review would lose the user's edits. Also the drawer badge's real count.
  final List<File> _queuedShares = [];
  final List<String> _queuedLinks = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.share?.attach(_onShared, onLink: _onSharedLink);
    });
  }

  @override
  void dispose() {
    widget.share?.detach();
    super.dispose();
  }

  void _select(int i) => setState(() {
        _tab = i;
        _built[i] = true;
      });

  Future<void> _import() async {
    if (_importBusy) return;
    _importBusy = true;
    try {
      // The sheet owns the pick now (3a): it pops with a typed choice.
      final choice = await showImportSheet(context,
          picker: widget.picker, camera: widget.camera);
      if (choice == null || !mounted) return;
      switch (choice) {
        case ImportManual():
          await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const ManualEntryScreen()));
        case ImportPicked(:final images, :final separate):
          if (images.isEmpty) return;
          if (separate) {
            // One queue item per shot (2b/3b); the sequential worker takes
            // over and the queue screen is non-blocking progress, not a gate.
            context.read<BatchModel>().addAll([
              for (final f in images) [f]
            ]);
            await _openImportQueue();
          } else {
            await _pushReview(images);
          }
      }
    } finally {
      _importBusy = false;
      _drainQueuedShares();
    }
  }

  Future<void> _openImportQueue() =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => BatchQueueScreen(
            extractor: widget.extractor, pickMore: widget.picker),
      ));

  void _onShared(List<File> images) {
    if (!mounted || images.isEmpty) return;
    if (_importBusy) {
      setState(() => _queuedShares.addAll(images));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Screenshot saved for your next import')));
      return;
    }
    _openShared(images);
  }

  Future<void> _openShared(List<File> images) async {
    _importBusy = true;
    try {
      await _pushReview(images);
    } finally {
      _importBusy = false;
      _drainQueuedShares();
    }
  }

  void _onSharedLink(String url) {
    if (!mounted || url.isEmpty) return;
    if (_importBusy) {
      setState(() => _queuedLinks.add(url));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link saved for your next import')));
      return;
    }
    _openSharedLink(url);
  }

  Future<void> _openSharedLink(String url) async {
    _importBusy = true;
    try {
      await _pushLinkReview(url);
    } finally {
      _importBusy = false;
      _drainQueuedShares();
    }
  }

  void _drainQueuedShares() {
    if (!mounted) return;
    if (_queuedShares.isNotEmpty) {
      final next = [..._queuedShares];
      setState(_queuedShares.clear);
      _openShared(next);
      return;
    }
    if (_queuedLinks.isEmpty) return;
    // One link at a time — each opens its own review, the rest keep waiting.
    final next = _queuedLinks.first;
    setState(() => _queuedLinks.removeAt(0));
    _openSharedLink(next);
  }

  Future<void> _pushReview(List<File> images) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ImportReviewScreen(
          images: images,
          extractor: widget.extractor,
          pickMore: widget.picker,
        ),
      ));

  /// Shared link → the same review flow, with the link extractor standing in
  /// for the vision model. No images: the page's own data is the source; a
  /// page without JSON-LD falls back to Gemini over the page text (an AI
  /// call, same cost as a screenshot).
  Future<void> _pushLinkReview(String url) {
    final gemini = widget.extractor;
    return Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ImportReviewScreen(
        images: const [],
        extractor: widget.linkExtractor?.call(url) ??
            LinkExtractor(
              url: url,
              client: linkFetchClient(),
              fallback: gemini is GeminiExtractor
                  ? gemini.extractContentFromText
                  : null,
              fallbackModel:
                  gemini is GeminiExtractor ? gemini.modelName : '',
            ),
        pickMore: widget.picker,
        fetchCover: (imageUrl) =>
            CoverFetcher(client: linkFetchClient()).fetch(imageUrl),
      ),
    ));
  }

  // The drawer Storage row's destination: the 3h screen. Restore refreshes
  // the library through this context — the pushed route shares the scope.
  void _openStorage() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => StorageScreen(
        folderName: widget.folderName,
        onChangeFolder: widget.onChangeFolder,
        onRestored: () => context.read<LibraryModel>().rescan(),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final batch = context.watch<BatchModel>();
    // The shell asserts its own status-bar style so returning from a route
    // that set its own (the black OriginalsViewer) can never leave light icons
    // stranded on the cream theme — Arnar's S21 pass, 2026-08-06.
    final overlay = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _tab,
          children: [
            RecipeListScreen(onImport: _import, onOpenQueue: _openImportQueue),
            _built[1] ? const GroceryTab() : const SizedBox.shrink(),
            // Slot 2: the pantry POC borrows the slot on dev builds (Arnar's
            // test call, 2026-08-17 — flag off restores Unlock untouched);
            // then the Unlock pitch — or, with both flags off, the queue
            // tab in its embedded form (no Hide/Done — a tab has nothing to
            // pop back to).
            if (kDiaryEnabled)
              // Slot 3 hosts Diary + Pantry behind one segmented control.
              _built[2] ? const FoodTab() : const SizedBox.shrink()
            else if (kPantryEnabled)
              _built[2] ? const PantryTab() : const SizedBox.shrink()
            else if (kUnlockTabEnabled)
              _built[2] ? const UnlockTab() : const SizedBox.shrink()
            else
              _built[2]
                  ? BatchQueueScreen(
                      extractor: widget.extractor,
                      pickMore: widget.picker,
                      embedded: true,
                    )
                  : const SizedBox.shrink(),
            // Settings reuses the drawer Storage row's exact destination wiring.
            _built[3]
                ? SettingsTab(
                    folderName: widget.folderName, onOpenStorage: _openStorage)
                : const SizedBox.shrink(),
            // Built, unreachable while kMealPlanEnabled is false — the tab
            // exists so the switch is one line when the engine lands.
            if (kMealPlanEnabled) const PlanTab(),
          ],
        ),
        bottomNavigationBar: GlassNavBar(
            active: _tab,
            onTab: _select,
            onFab: _import,
            queueBadge:
                batch.attention + _queuedShares.length + _queuedLinks.length),
      ),
    );
  }
}
