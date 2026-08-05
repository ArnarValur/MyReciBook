// Import review: spinner → failed(retry on cached picks, D5) → editable form.
// D6 pre-save scope: title + any raw line; parsed fields stay untouched.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/extractor.dart';
import '../domain/recipe.dart';
import '../domain/validate.dart';
import 'library_model.dart';

enum _Phase { extracting, failed, review }

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.images,
    required this.extractor,
    required this.pickMore,
  });

  final List<File> images;
  final Extractor extractor;
  final Future<List<File>> Function() pickMore;

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen> {
  // Cached picks are the retry artifact (D5 — no inbox, no queue).
  late final List<File> _images = [...widget.images];

  _Phase _phase = _Phase.extracting;
  String _error = '';
  Map<String, dynamic> _content = const {};

  final TextEditingController _title = TextEditingController();
  List<TextEditingController> _ingredientCtrls = const [];
  List<TextEditingController> _stepCtrls = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  @override
  void dispose() {
    _title.dispose();
    _disposeLineCtrls();
    super.dispose();
  }

  void _disposeLineCtrls() {
    for (final c in _ingredientCtrls) {
      c.dispose();
    }
    for (final c in _stepCtrls) {
      c.dispose();
    }
  }

  List<Map<String, dynamic>> get _ings => [
        for (final i in (_content['ingredients'] as List? ?? const []))
          (i as Map).cast<String, dynamic>()
      ];

  List<Map<String, dynamic>> get _steps => [
        for (final s in (_content['steps'] as List? ?? const []))
          (s as Map).cast<String, dynamic>()
      ];

  List<String> get _needsReview {
    final ex = _content['extraction'];
    return ex is Map
        ? [for (final p in (ex['needs_review'] as List? ?? const [])) p as String]
        : const [];
  }

  static String _classify(ExtractionException e) {
    if (e.httpStatus == 429) return 'Rate-limited — try again in a minute.';
    if (e.message.startsWith('offline')) return 'Offline — check your connection.';
    return 'Extraction failed — try again.';
  }

  Future<void> _extract() async {
    setState(() => _phase = _Phase.extracting);
    try {
      final content = await widget.extractor.extractContent(_images);
      if (!mounted) return;
      setState(() {
        _content = content;
        _title.text = (content['title'] as String?) ?? '';
        _disposeLineCtrls();
        _ingredientCtrls = [
          for (final i in _ings)
            TextEditingController(text: (i['raw'] as String?) ?? '')
        ];
        _stepCtrls = [
          for (final s in _steps)
            TextEditingController(text: (s['raw'] as String?) ?? '')
        ];
        _phase = _Phase.review;
      });
    } on ExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = _classify(e);
      });
    } catch (e) {
      // Safety net: anything else escaping here strands the spinner forever —
      // the exact dead-end the failed→retry flow (D5) exists to prevent.
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = 'Extraction failed — try again.';
      });
    }
  }

  Future<void> _addImages() async {
    final more = await widget.pickMore();
    if (more.isEmpty || !mounted) return;
    _images.addAll(more);
    // Re-extract over the full list; edits are lost (accepted v1, arch §3.4).
    await _extract();
  }

  Future<void> _save() async {
    _content['title'] = _title.text.trim();
    final ings = _content['ingredients'] as List? ?? const [];
    for (var i = 0; i < _ingredientCtrls.length && i < ings.length; i++) {
      (ings[i] as Map)['raw'] = _ingredientCtrls[i].text;
    }
    final steps = _content['steps'] as List? ?? const [];
    for (var i = 0; i < _stepCtrls.length && i < steps.length; i++) {
      (steps[i] as Map)['raw'] = _stepCtrls[i].text;
    }

    final recipe = Recipe.assemble(
      id: const Uuid().v4(),
      content: _content,
      originalImages: [for (final f in _images) f.path],
      importedAt: DateTime.now(),
      extractorModel: widget.extractor.modelName,
      extractorMode: widget.extractor.mode,
    );
    final blocking =
        fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (blocking.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(blocking.join(' · '))));
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<LibraryModel>().saveImported(recipe, _images);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  bool _flagTitle() => _needsReview.contains('title');

  bool _flagIngredient(int i) {
    final conf = (_ings[i]['confidence'] as num?)?.toDouble();
    return (conf != null && conf < 0.8) ||
        _needsReview.any((p) => p.startsWith('ingredients[$i]'));
  }

  bool _flagStep(int i) {
    final conf = (_steps[i]['confidence'] as num?)?.toDouble();
    return (conf != null && conf < 0.8) ||
        _needsReview.any((p) => p.startsWith('steps[$i]'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review import'),
        actions: [
          if (_phase == _Phase.review)
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: switch (_phase) {
        _Phase.extracting => const Center(child: CircularProgressIndicator()),
        _Phase.failed => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _extract,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        _Phase.review => _reviewForm(context),
      },
    );
  }

  Widget _reviewForm(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium;
    final children = <Widget>[
      TextField(
        controller: _title,
        decoration: InputDecoration(
          labelText: 'Title',
          suffixIcon: _flagTitle() ? const Icon(Icons.warning_amber) : null,
        ),
      ),
      const SizedBox(height: 16),
      if (_steps.isEmpty)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                    'No steps captured — add another screenshot of the method'),
                TextButton(
                  onPressed: _addImages,
                  child: const Text('Add screenshot'),
                ),
              ],
            ),
          ),
        ),
      Text('Ingredients', style: labelStyle),
    ];

    String? prevGroup;
    final ings = _ings;
    for (var i = 0; i < _ingredientCtrls.length && i < ings.length; i++) {
      final group = ings[i]['group'] as String?;
      if (group != null && group != prevGroup) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(group, style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      prevGroup = group;
      children.add(TextField(
        controller: _ingredientCtrls[i],
        decoration: InputDecoration(
          suffixIcon:
              _flagIngredient(i) ? const Icon(Icons.warning_amber) : null,
        ),
      ));
    }

    if (_stepCtrls.isNotEmpty) {
      children
        ..add(const SizedBox(height: 16))
        ..add(Text('Steps', style: labelStyle));
      for (var i = 0; i < _stepCtrls.length; i++) {
        children.add(TextField(
          controller: _stepCtrls[i],
          maxLines: null,
          decoration: InputDecoration(
            labelText: '${i + 1}',
            suffixIcon: _flagStep(i) ? const Icon(Icons.warning_amber) : null,
          ),
        ));
      }
    }

    return ListView(padding: const EdgeInsets.all(16), children: children);
  }
}
