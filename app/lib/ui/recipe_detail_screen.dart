// Detail: read-only view + notes editing only post-save (D6) + delete.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/recipe.dart';
import 'library_model.dart';

class RecipeDetailScreen extends StatefulWidget {
  const RecipeDetailScreen({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late Recipe _recipe = widget.recipe;
  late final TextEditingController _notes =
      TextEditingController(text: widget.recipe.notes ?? '');

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    // Empty cachedImages keeps original_images intact (store contract).
    final Recipe saved;
    try {
      saved = await context
          .read<LibraryModel>()
          .saveImported(_recipe.copyWith(notes: _notes.text), const []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    if (!mounted) return;
    setState(() => _recipe = saved);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notes saved')));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text('"${_recipe.title}" and its images will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await context.read<LibraryModel>().delete(_recipe.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;
    final children = <Widget>[
      if (_recipe.servings?.raw != null)
        Text('Servings: ${_recipe.servings!.raw}'),
      if (_recipe.times?.raw != null) Text('Time: ${_recipe.times!.raw}'),
      const SizedBox(height: 16),
      Text('Ingredients', style: labelStyle),
    ];

    String? prevGroup;
    for (final i in _recipe.ingredients) {
      if (i.group != null && i.group != prevGroup) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(i.group!, style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      prevGroup = i.group;
      children.add(Text(i.raw));
    }

    children
      ..add(const SizedBox(height: 16))
      ..add(Text('Steps', style: labelStyle));
    for (var n = 0; n < _recipe.steps.length; n++) {
      children.add(Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('${n + 1}. ${_recipe.steps[n].raw}'),
      ));
    }

    children
      ..add(const SizedBox(height: 16))
      ..add(Text('Notes', style: labelStyle))
      ..add(TextField(
        key: const Key('notes-field'),
        controller: _notes,
        maxLines: null,
        decoration: const InputDecoration(hintText: 'Your notes'),
      ))
      ..add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _saveNotes,
          child: const Text('Save notes'),
        ),
      ));

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe.title),
        actions: [
          IconButton(icon: const Icon(Icons.delete), onPressed: _delete),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );
  }
}
