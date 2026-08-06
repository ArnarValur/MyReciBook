// App shell — the promoted turn-4 nav, confirmed by turn 5: glass pill bar
// over the four daily surfaces with the gradient FAB as the import door, plus
// the 5c drawer. Lives only inside BootGate's ready phase; gate and migration
// stay shell-less. The shell owns the ShareEntry attach point and the import
// flow so shares land in review from any tab; pushed routes cover the bar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:provider/provider.dart';

import '../data/share_entry.dart';
import '../domain/extractor.dart';
import 'app_drawer.dart';
import 'grocery_tab.dart';
import 'import_review_screen.dart';
import 'import_sheet.dart';
import 'library_model.dart';
import 'plan_tab.dart';
import 'recipe_list_screen.dart';
import 'settings_tab.dart';
import 'storage_model.dart';
import 'storage_screen.dart';
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

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;

  // Lazy tabs: a surface is built on first visit and then kept alive, so
  // finders and IO stay quiet until a tester actually goes there.
  final List<bool> _built = [true, false, false, false];

  bool _importBusy = false;

  // Shares arriving while an import is open wait here — hijacking an open
  // review would lose the user's edits. Also the drawer badge's real count.
  final List<File> _queuedShares = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.share?.attach(_onShared);
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
      final source =
          await showImportSheet(context, withCamera: widget.camera != null);
      if (source == null || !mounted) return;

      final List<File> picks;
      try {
        picks = await (source == ImportSource.camera
            ? widget.camera!()
            : widget.picker());
      } on PlatformException {
        return; // double-tap races the native picker ('already_active')
      }
      if (picks.isEmpty || !mounted) return;
      await _pushReview(picks);
    } finally {
      _importBusy = false;
      _drainQueuedShares();
    }
  }

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

  void _drainQueuedShares() {
    if (!mounted || _queuedShares.isEmpty) return;
    final next = [..._queuedShares];
    setState(_queuedShares.clear);
    _openShared(next);
  }

  Future<void> _pushReview(List<File> images) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => ImportReviewScreen(
          images: images,
          extractor: widget.extractor,
          pickMore: widget.picker,
        ),
      ));

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
    final storage = context.watch<StorageModel>();
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      drawerScrimColor: const Color(0x730B0D16),
      drawer: AppDrawer(
        activeTab: _tab,
        queuedImports: _queuedShares.length,
        storageLabel: storage.drawerSummary(folderName: widget.folderName),
        storageCloud: storage.active != null,
        onSelectTab: _select,
        onOpenStorage: _openStorage,
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          RecipeListScreen(
            onImport: _import,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          _built[1] ? const GroceryTab() : const SizedBox.shrink(),
          _built[2] ? const PlanTab() : const SizedBox.shrink(),
          _built[3] ? const SettingsTab() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar:
          GlassNavBar(active: _tab, onTab: _select, onFab: _import),
    );
  }
}
