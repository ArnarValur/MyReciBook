// Batch queue (design 3b, PROMOTED from the dev-gallery preview) —
// non-blocking progress for multi-imports; only flagged items demand
// attention. Session state only (D5): backed by BatchModel above the shell,
// so the queue survives tab switches and dies with the app.
//
// DEVIATIONS (undesigned states, for Arnar to ratify):
// - failed card: the flagged-card pattern in the error color + "Retry" — 3b
//   draws no transport-failure card; captions keep 4c's calm register.
// - skipped card: dimmed, "not a recipe — skipped, nothing saved" (2a
//   promises the state; no hi-fi card exists).
// - done-state header: "Recipes rescued" + honest count summary (3b only
//   draws the running state); reviewed items caption "saved · you checked
//   it" vs the designed auto-save "saved · looked complete".
// - running header gains an "N of M done" progress line (the wired queue
//   needs overall progress; the mockup's static frame didn't).
// - empty state (drawer entry, no batch yet): quiet caption.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/extractor.dart';
import '../domain/recipe.dart';
import 'batch_model.dart';
import 'import_review_screen.dart';
import 'theme.dart';
import 'widgets/skin.dart';

class BatchQueueScreen extends StatelessWidget {
  const BatchQueueScreen(
      {super.key, required this.extractor, required this.pickMore});

  final Extractor extractor;
  final Future<List<File>> Function() pickMore;

  Future<void> _reviewNow(
      BuildContext context, BatchModel model, BatchItem item) async {
    final saved = await Navigator.of(context).push<Recipe>(MaterialPageRoute(
      builder: (_) => ImportReviewScreen.prefilled(
        images: item.images,
        content: item.content!,
        extractor: extractor,
        pickMore: pickMore,
      ),
    ));
    if (saved != null) model.markReviewed(item, saved);
  }

  static String _recipes(int n) => n == 1 ? '1 recipe' : '$n recipes';

  String _summary(BatchModel model) {
    final flagged = model.items
        .where((i) => i.state == BatchItemState.needsReview)
        .length;
    final failed =
        model.items.where((i) => i.state == BatchItemState.failed).length;
    final parts = <String>[
      if (model.savedCount > 0) '${model.savedCount} saved',
      if (flagged > 0)
        flagged == 1 ? '1 needs your eyes' : '$flagged need your eyes',
      if (failed > 0) '$failed failed',
      if (model.skippedCount > 0) '${model.skippedCount} skipped',
    ];
    return parts.isEmpty ? 'Nothing here yet.' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<BatchModel>();
    final items = model.items;
    final flagged = [
      for (final i in items)
        if (i.state == BatchItemState.needsReview) i
    ];
    final running = model.remaining > 0;

    final String title;
    final String caption;
    if (items.isEmpty) {
      title = 'Import queue';
      caption = 'Rescue screenshots as separate recipes and they line up here.';
    } else if (running) {
      title = 'Rescuing ${_recipes(items.length)}…';
      caption = "Keep browsing — we'll line them up for a quick check.";
    } else {
      title = 'Recipes rescued';
      caption = _summary(model);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(title,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontSize: 22)),
                  ),
                  TextButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Hide')),
                ],
              ),
              Text(caption,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
              if (running) ...[
                const SizedBox(height: 4),
                Text(
                  '${items.length - model.remaining} of ${items.length} done',
                  key: const Key('batch-progress-line'),
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ItemCard(
                          item: item,
                          onReview: () => _reviewNow(context, model, item),
                          onRetry: () => model.retry(item),
                        ),
                      ),
                    const DashedInfoCard(
                        text:
                            'Not a recipe? We skip it and say so — no junk lands in your book.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (flagged.isNotEmpty) ...[
                    Expanded(
                      child: OutlinedButton(
                          onPressed: () =>
                              _reviewNow(context, model, flagged.first),
                          child: Text('Review flagged · ${flagged.length}')),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Done')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard(
      {required this.item, required this.onReview, required this.onRetry});

  final BatchItem item;
  final VoidCallback onReview;
  final VoidCallback onRetry;

  String _reviewCaption() {
    final steps = item.content?['steps'] as List? ?? const [];
    if (steps.isEmpty) return 'no steps captured — needs another shot';
    final n = item.flaggedLines;
    if (n == 1) return '1 line needs your eyes';
    if (n > 1) return '$n lines need your eyes';
    return 'needs your eyes';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;

    Widget thumb() => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
              width: 44, height: 60, child: CoverImage(item.images.firstOrNull)),
        );

    Widget texts(String title, String caption, {Color? captionColor}) =>
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight:
                          captionColor == null ? null : FontWeight.w500,
                      color: captionColor ?? scheme.onSurfaceVariant)),
            ],
          ),
        );

    ButtonStyle smallTonal() => FilledButton.styleFrom(
        minimumSize: const Size(76, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14));

    switch (item.state) {
      case BatchItemState.waiting:
        return Opacity(
          opacity: 0.65,
          child: TokenCard(
            shadow: false,
            child: Row(children: [
              thumb(),
              const SizedBox(width: 12),
              Text('Waiting…',
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ]),
          ),
        );
      case BatchItemState.extracting:
        return TokenCard(
          child: Row(children: [
            thumb(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Extracting…',
                      style:
                          theme.textTheme.titleSmall?.copyWith(fontSize: 15)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHigh),
                  ),
                ],
              ),
            ),
          ]),
        );
      case BatchItemState.saved:
        return TokenCard(
          child: Row(children: [
            thumb(),
            const SizedBox(width: 12),
            texts(item.title,
                item.reviewed ? 'saved · you checked it' : 'saved · looked complete'),
            const Icon(Icons.check_circle_rounded,
                color: RbColors.success, size: 24),
          ]),
        );
      case BatchItemState.needsReview:
        return TokenCard(
          borderColor: RbColors.warning.withValues(alpha: 0.55),
          borderWidth: 1.5,
          child: Row(children: [
            thumb(),
            const SizedBox(width: 12),
            texts(item.title, _reviewCaption(),
                captionColor: Color.alphaBlend(
                    RbColors.warning.withValues(alpha: 0.55),
                    scheme.onSurface)),
            FilledButton.tonal(
                onPressed: onReview,
                style: smallTonal(),
                child: const Text('Review')),
          ]),
        );
      case BatchItemState.failed:
        return TokenCard(
          borderColor: scheme.error.withValues(alpha: 0.55),
          borderWidth: 1.5,
          child: Row(children: [
            thumb(),
            const SizedBox(width: 12),
            texts(item.title, item.error ?? 'failed · tap retry',
                captionColor: Color.alphaBlend(
                    scheme.error.withValues(alpha: 0.7), scheme.onSurface)),
            FilledButton.tonal(
                onPressed: onRetry,
                style: smallTonal(),
                child: const Text('Retry')),
          ]),
        );
      case BatchItemState.skipped:
        return Opacity(
          opacity: 0.65,
          child: TokenCard(
            shadow: false,
            child: Row(children: [
              thumb(),
              const SizedBox(width: 12),
              texts(item.title, 'not a recipe — skipped, nothing saved'),
              Icon(Icons.no_meals_rounded,
                  size: 22, color: scheme.onSurfaceVariant),
            ]),
          ),
        );
    }
  }
}
