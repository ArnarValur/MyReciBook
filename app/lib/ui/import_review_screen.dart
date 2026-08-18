// Import review (design 3c; calm failure 4c): spinner → failed(retry on
// cached picks, D5) → suggest-and-confirm review. D6 pre-save scope: title +
// any raw line; parsed fields stay untouched. Flagged lines get the warning
// treatment + a confirm chip — never silently auto-saved (§6.3).
//
// The hi-fi's delete-screenshot toggle ships OFF-by-default per review note 1;
// it is omitted entirely until the engine can delete gallery originals.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../data/saf_store.dart';
import '../domain/extractor.dart';
import '../domain/recipe.dart';
import '../domain/validate.dart';
import 'library_model.dart';
import 'theme.dart';
import 'widgets/skin.dart';

enum _Phase { extracting, failed, review }

class ImportReviewScreen extends StatefulWidget {
  const ImportReviewScreen({
    super.key,
    required this.images,
    required Extractor this.extractor,
    required Future<List<File>> Function() this.pickMore,
  })  : editing = null,
        initialContent = null;

  /// Batch hand-off (3b "Review"): the queue already holds an extraction —
  /// review seeds from it, no fresh AI call. Retry and add-screenshot still
  /// re-extract over the cached picks. Pops with the saved Recipe.
  const ImportReviewScreen.prefilled({
    super.key,
    required this.images,
    required Map<String, dynamic> content,
    required Extractor this.extractor,
    required Future<List<File>> Function() this.pickMore,
  })  : editing = null,
        initialContent = content;

  /// Post-save edit (D6 as amended 2026-08-06): the saved recipe reopens in
  /// this screen and saves back over the same file. Text-level only — no
  /// re-extraction, no image changes — so the envelope (source images,
  /// extraction stamps, notes, favorite) survives untouched. [originals] are
  /// the hydrated stored images, display-only. Pops with the saved Recipe.
  const ImportReviewScreen.edit({
    super.key,
    required Recipe recipe,
    required List<File> originals,
  })  : editing = recipe,
        images = originals,
        extractor = null,
        pickMore = null,
        initialContent = null;

  final List<File> images;
  final Extractor? extractor;
  final Future<List<File>> Function()? pickMore;
  final Recipe? editing;

  /// Pre-extracted content from the batch queue; null = extract on mount.
  final Map<String, dynamic>? initialContent;

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
  // Flag dismissal is per-line UI state: confirmed or edited lines normalize.
  final Set<String> _confirmed = {};
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _disposeLineCtrls();
    super.dispose();
  }

  bool get _isEdit => widget.editing != null;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing == null) {
      final pre = widget.initialContent;
      if (pre != null) {
        _seed(pre); // batch hand-off: the extraction already happened
      } else {
        _extract();
      }
      return;
    }
    // Edit mode: seed straight from the saved file — no extraction call.
    // toJson() builds fresh maps, so the write-back in _save mutates copies.
    _content = editing.toJson();
    _title.text = editing.title;
    _ingredientCtrls = [
      for (final i in editing.ingredients) TextEditingController(text: i.raw)
    ];
    _stepCtrls = [
      for (final s in editing.steps) TextEditingController(text: s.raw)
    ];
    _phase = _Phase.review;
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

  static ({String title, String body}) _classify(ExtractionException e) {
    if (e.httpStatus == 429) {
      return (
        title: 'Give it a minute',
        body: 'Rate-limited — try again shortly.'
      );
    }
    if (e.message.startsWith('offline')) {
      return (
        title: "You're offline",
        body: 'Check your connection, then try again.'
      );
    }
    if (e.message.startsWith('no recipe data')) {
      // Link import (share-links spike): the page had no schema.org Recipe.
      return (
        title: 'No recipe in that link',
        body: "The page doesn't share its recipe data — "
            'screenshot it instead.'
      );
    }
    if (e.message.startsWith('unreadable response')) {
      return (
        title: "That site confused us",
        body: 'Its reply made no sense to the app — '
            'screenshot the recipe instead.'
      );
    }
    if (e.message.startsWith('the page answered')) {
      return (
        title: "The site wouldn't let us in",
        body: 'It refused the request — screenshot the recipe instead.'
      );
    }
    if (e.message.startsWith('No API key')) {
      // A keyless build (flutter build without dev.env) is OUR defect, never
      // the user's screenshots — twice in one day (2026-08-18) it hid behind
      // the generic copy below and burned Arnar's time. Name it.
      return (
        title: 'This build is broken',
        body: 'Built without the extraction key — not your screenshots. '
            'Rebuild with dev.env.'
      );
    }
    return (
      title: 'That one kept its secrets',
      body: "We read it twice and couldn't find a recipe."
    );
  }

  /// Seeds review state from extraction [content]; wrap in setState when the
  /// frame is already live (initState may call it bare).
  void _seed(Map<String, dynamic> content) {
    _content = content;
    _title.text = (content['title'] as String?) ?? '';
    _disposeLineCtrls();
    _confirmed.clear();
    _ingredientCtrls = [
      for (final i in _ings)
        TextEditingController(text: (i['raw'] as String?) ?? '')
    ];
    _stepCtrls = [
      for (final s in _steps)
        TextEditingController(text: (s['raw'] as String?) ?? '')
    ];
    _phase = _Phase.review;
  }

  Future<void> _extract() async {
    setState(() => _phase = _Phase.extracting);
    try {
      final content = await widget.extractor!.extractContent(_images);
      if (!mounted) return;
      setState(() => _seed(content));
    } on ExtractionException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = '${_classify(e).title}\n${_classify(e).body}';
      });
    } catch (e) {
      // Safety net: anything else escaping here strands the spinner forever —
      // the exact dead-end the failed→retry flow (D5) exists to prevent.
      if (!mounted) return;
      setState(() {
        _phase = _Phase.failed;
        _error = 'That one kept its secrets\nExtraction failed — try again.';
      });
    }
  }

  Future<void> _addImages() async {
    final more = await widget.pickMore!();
    if (more.isEmpty || !mounted) return;
    _images.addAll(more);
    // Re-extract over the full list; edits are lost (accepted v1, arch §3.4).
    await _extract();
  }

  Future<void> _save() async {
    final Recipe recipe;
    final editing = widget.editing;
    if (editing != null) {
      // Text-level save-back: copyWith keeps the envelope — id, source images,
      // extraction stamps (rule 2: no extraction happened, nothing re-stamps),
      // notes, favorite.
      recipe = editing.copyWith(
        title: _title.text.trim(),
        ingredients: [
          for (var i = 0; i < editing.ingredients.length; i++)
            editing.ingredients[i].copyWith(
                raw: i < _ingredientCtrls.length
                    ? _ingredientCtrls[i].text
                    : editing.ingredients[i].raw)
        ],
        steps: [
          for (var i = 0; i < editing.steps.length; i++)
            editing.steps[i].copyWith(
                raw: i < _stepCtrls.length
                    ? _stepCtrls[i].text
                    : editing.steps[i].raw)
        ],
      );
    } else {
      _content['title'] = _title.text.trim();
      final ings = _content['ingredients'] as List? ?? const [];
      for (var i = 0; i < _ingredientCtrls.length && i < ings.length; i++) {
        (ings[i] as Map)['raw'] = _ingredientCtrls[i].text;
      }
      final steps = _content['steps'] as List? ?? const [];
      for (var i = 0; i < _stepCtrls.length && i < steps.length; i++) {
        (steps[i] as Map)['raw'] = _stepCtrls[i].text;
      }

      recipe = Recipe.assemble(
        id: const Uuid().v4(),
        content: _content,
        originalImages: [for (final f in _images) f.path],
        importedAt: DateTime.now(),
        extractorModel: widget.extractor!.modelName,
        extractorMode: widget.extractor!.mode,
      );
    }
    final blocking =
        fileProblems(recipe.toJson()).where(isSaveBlocking).toList();
    if (blocking.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(blocking.join(' · '))));
      return;
    }

    setState(() => _saving = true);
    final Recipe saved;
    try {
      // Edit mode: empty cachedImages keeps original_images intact (store
      // contract) — the same seam notes/favorite edits already ride.
      saved = await context
          .read<LibraryModel>()
          .saveImported(recipe, _isEdit ? const [] : _images);
    } on GrantLostException {
      // Review stays mounted — edits and extraction survive; re-pick happens
      // from the list, not by tearing down in-flight work (§7).
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Folder access was lost — your edits are kept. '
              'Try again, or go back and re-pick your folder.')));
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      return;
    }
    // Pops with the saved Recipe in every mode — edit (detail awaits it) and
    // batch review-now (the queue marks the item saved) both consume it.
    if (mounted) Navigator.of(context).pop(saved);
  }

  bool _flagTitle() => _needsReview.contains('title');

  bool _flagIngredient(int i) {
    if (_confirmed.contains('i$i')) return false;
    final conf = (_ings[i]['confidence'] as num?)?.toDouble();
    return (conf != null && conf < 0.8) ||
        _needsReview.any((p) => p.startsWith('ingredients[$i]'));
  }

  bool _flagStep(int i) {
    if (_confirmed.contains('s$i')) return false;
    final conf = (_steps[i]['confidence'] as num?)?.toDouble();
    return (conf != null && conf < 0.8) ||
        _needsReview.any((p) => p.startsWith('steps[$i]'));
  }

  void _openOriginals() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => OriginalsViewer(images: _images),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_phase) {
          _Phase.extracting => _extracting(context),
          _Phase.failed => _failed(context),
          _Phase.review => _review(context),
        },
      ),
    );
  }

  Widget _topBar(BuildContext context, {required bool rescued}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const AppBackButton(),
        Expanded(
          child: Row(
            children: [
              // DEVIATION: edit-mode copy undesigned (D6 amendment predates a
              // mockup for it) — 'Edit recipe' / 'Save changes' for Arnar to
              // ratify or redraw.
              Text(
                  _isEdit
                      ? 'Edit recipe'
                      : rescued
                          ? 'Recipe rescued'
                          : 'Rescue',
                  style: theme.textTheme.titleLarge),
              if (rescued && !_isEdit) ...[
                const SizedBox(width: 6),
                const Icon(Icons.check_circle_rounded,
                    size: 19, color: RbColors.success),
              ],
            ],
          ),
        ),
        if (rescued && !_isEdit)
          TextButton(onPressed: _extract, child: const Text('Retry')),
      ],
    );
  }

  Widget _extracting(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        _topBar(context, rescued: false),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 140,
                    child: CoverImage(_images.firstOrNull),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                    width: 160, child: LinearProgressIndicator(minHeight: 6)),
                const SizedBox(height: 14),
                Text('Rescuing…',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: context.scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Calm, no blame (4c): what happened, what didn't happen, one way forward.
  Widget _failed(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final lines = _error.split('\n');
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context, rescued: false),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 140,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.rb.hairline),
                    ),
                    child: const StripedPlaceholder(
                        icon: Icons.no_meals_rounded),
                  ),
                  const SizedBox(height: 18),
                  Text(lines.first,
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.headlineSmall?.copyWith(fontSize: 21)),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: Text(
                      '${lines.length > 1 ? lines[1] : ''} Your screenshot '
                      'stays put in your gallery — nothing was deleted.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _extract,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _review(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final rb = context.rb;

    final servingsRaw =
        (_content['servings'] is Map) ? _content['servings']['raw'] : null;
    final timesRaw =
        (_content['times'] is Map) ? _content['times']['raw'] : null;

    // Link import (share-links spike): no screenshots — the source row names
    // the page instead, and there are no originals to open.
    final sourceUrl = _content['source'] is Map
        ? (_content['source'] as Map)['url'] as String?
        : null;
    final fromLink = _images.isEmpty && sourceUrl != null;

    final children = <Widget>[
      // Source row — provenance is one tap away, always.
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: fromLink ? null : _openOriginals,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                  width: 52,
                  height: 76,
                  child: fromLink
                      ? ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(Icons.link_rounded,
                              size: 24, color: scheme.onSurfaceVariant),
                        )
                      : CoverImage(_images.firstOrNull)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      fromLink
                          ? 'From a link'
                          : _images.length > 1
                              ? 'Original screenshots · ${_images.length}'
                              : 'Original screenshot',
                      style:
                          theme.textTheme.titleSmall?.copyWith(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                      fromLink
                          ? (Uri.tryParse(sourceUrl)?.host ?? sourceUrl)
                          : 'tap to see what we read',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (!fromLink)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh, shape: BoxShape.circle),
                child: Icon(Icons.swap_horiz_rounded,
                    size: 20, color: scheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      // Title card — inline editable (D6).
      TokenCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        borderColor: _flagTitle() ? RbColors.warning : null,
        borderWidth: _flagTitle() ? 1.5 : null,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _title,
                style: theme.textTheme.titleLarge,
                decoration: const InputDecoration(
                    isCollapsed: true, border: InputBorder.none),
              ),
            ),
            Icon(Icons.edit_rounded, size: 19, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
      if (servingsRaw != null || timesRaw != null) ...[
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (servingsRaw != null)
              MetaChip(icon: Icons.restaurant_rounded, label: '$servingsRaw'),
            if (timesRaw != null)
              MetaChip(icon: Icons.schedule_rounded, label: '$timesRaw'),
          ],
        ),
      ],
      const SizedBox(height: 14),
      // Edit mode is text-level (D6 amendment): re-extraction over the saved
      // recipe would clobber it from stale screenshots, so no add-screenshot.
      if (_steps.isEmpty && !_isEdit) ...[
        // D4: incomplete capture — ask for another screenshot, never invent.
        TokenCard(
          borderColor: RbColors.warning.withValues(alpha: 0.55),
          borderWidth: 1.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No steps captured — add another screenshot of the method'),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _addImages,
                child: const Text('Add screenshot'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      SectionLabel('Ingredients · ${_ingredientCtrls.length}'),
      const SizedBox(height: 8),
      TokenCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(children: _ingredientRows(theme, scheme, rb)),
      ),
      if (_stepCtrls.isNotEmpty) ...[
        const SizedBox(height: 14),
        SectionLabel('Steps · ${_stepCtrls.length}'),
        const SizedBox(height: 8),
        TokenCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Column(children: _stepRows(theme, scheme, rb)),
        ),
      ],
      const SizedBox(height: 20),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: Text(_isEdit ? 'Save changes' : 'Save to cookbook'),
      ),
      const SizedBox(height: 8),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _topBar(context, rescued: true),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: children,
          ),
        ),
      ],
    );
  }

  List<Widget> _ingredientRows(
      ThemeData theme, ColorScheme scheme, RbTokens rb) {
    final rows = <Widget>[];
    String? prevGroup;
    final ings = _ings;
    for (var i = 0; i < _ingredientCtrls.length && i < ings.length; i++) {
      final group = ings[i]['group'] as String?;
      if (group != null && group != prevGroup) {
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 2),
          child: Align(
              alignment: Alignment.centerLeft, child: SectionLabel(group)),
        ));
      }
      prevGroup = group;
      final flagged = _flagIngredient(i);
      final last = i == _ingredientCtrls.length - 1;

      final field = TextField(
        controller: _ingredientCtrls[i],
        style: theme.textTheme.bodyMedium,
        maxLines: null,
        onChanged: (_) {
          if (_flagIngredient(i)) setState(() => _confirmed.add('i$i'));
        },
        decoration: const InputDecoration(
            isCollapsed: true, border: InputBorder.none),
      );

      if (flagged) {
        // Suggest-and-confirm: warning tint + an explicit confirm chip.
        rows.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: RbColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(child: field),
              const SizedBox(width: 8),
              InkWell(
                key: Key('confirm-ingredient-$i'),
                borderRadius: BorderRadius.circular(999),
                onTap: () => setState(() => _confirmed.add('i$i')),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: RbColors.warning.withValues(alpha: 0.7),
                        width: 1.5),
                  ),
                  child: Text(
                    'confirm',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                      color: Color.alphaBlend(
                          RbColors.warning.withValues(alpha: 0.55),
                          scheme.onSurface),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
      } else {
        rows.add(Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: rb.separator))),
          child: field,
        ));
      }
    }
    return rows;
  }

  List<Widget> _stepRows(ThemeData theme, ColorScheme scheme, RbTokens rb) {
    final rows = <Widget>[];
    for (var i = 0; i < _stepCtrls.length; i++) {
      final flagged = _flagStep(i);
      final last = i == _stepCtrls.length - 1;
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${i + 1}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: scheme.primary, fontSize: 13.5)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _stepCtrls[i],
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              maxLines: null,
              onChanged: (_) {
                if (_flagStep(i)) setState(() => _confirmed.add('s$i'));
              },
              decoration: const InputDecoration(
                  isCollapsed: true, border: InputBorder.none),
            ),
          ),
        ],
      );
      if (flagged) {
        rows.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: RbColors.warning.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: row,
        ));
      } else {
        rows.add(Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: rb.separator))),
          child: row,
        ));
      }
    }
    return rows;
  }
}
