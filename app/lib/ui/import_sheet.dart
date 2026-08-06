// Import sheet (design 3a, single-recipe path — batch and the link door are
// post-alpha). A chooser, not a form: pick a source, the sheet closes, and the
// existing import flow takes over.

import 'package:flutter/material.dart';

import 'theme.dart';
import 'widgets/skin.dart';

enum ImportSource { screenshots, camera }

/// Slides up over a 45% scrim; resolves to the chosen source or null.
Future<ImportSource?> showImportSheet(BuildContext context,
    {bool withCamera = true}) {
  return showModalBottomSheet<ImportSource>(
    context: context,
    barrierColor: const Color(0x730B0D16),
    builder: (context) => _ImportSheet(withCamera: withCamera),
  );
}

class _ImportSheet extends StatelessWidget {
  const _ImportSheet({required this.withCamera});

  final bool withCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text('Add to your book',
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 12),
            const SectionLabel('From your screenshots'),
            const SizedBox(height: 8),
            InkWell(
              key: const Key('import-screenshots-tile'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context, ImportSource.screenshots),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.photo_library_rounded,
                          size: 20, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose screenshots',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'pick every shot of one recipe — we stitch them together',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (withCamera) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: context.rb.hairline),
              const SizedBox(height: 12),
              InkWell(
                key: const Key('import-camera-tile'),
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.pop(context, ImportSource.camera),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.photo_camera_rounded,
                            size: 20, color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Snap a page',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              "cookbook or grandma's card — handwriting welcome",
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
