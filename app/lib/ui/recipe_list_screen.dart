import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:provider/provider.dart';

import '../domain/extractor.dart';
import 'import_review_screen.dart';
import 'library_model.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen(
      {super.key, required this.extractor, required this.picker});

  final Extractor extractor;
  final Future<List<File>> Function() picker;

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<LibraryModel>().rescan();
    });
  }

  Future<void> _import() async {
    if (_picking) return;
    _picking = true;
    final List<File> picks;
    try {
      picks = await widget.picker();
    } on PlatformException {
      return; // double-tap races the native picker ('already_active')
    } finally {
      _picking = false;
    }
    if (picks.isEmpty || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ImportReviewScreen(
        images: picks,
        extractor: widget.extractor,
        pickMore: widget.picker,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<LibraryModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('MyReciBook')),
      body: model.loading && model.recipes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => context.read<LibraryModel>().rescan(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (model.recipes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                          'No recipes yet — tap + to import your first screenshot.'),
                    ),
                  for (final r in model.recipes)
                    ListTile(
                      title: Text(r.title),
                      subtitle: Text('${r.ingredients.length} ingredients'),
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => RecipeDetailScreen(recipe: r),
                      )),
                    ),
                  if (model.skipped > 0)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "${model.skipped} files in the folder couldn't be read",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _import,
        child: const Icon(Icons.add),
      ),
    );
  }
}
