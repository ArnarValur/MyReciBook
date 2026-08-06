// Dev gallery — debug-only door (long-press the wordmark) to the post-alpha
// screens. Constraint 4 as amended: building ahead is cheap and allowed; these
// ship only when their engines land (batch queue, billing, connectors,
// grocery, cap counter). Demo data mirrors the hi-fi mockups verbatim.

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/skin.dart';
import 'preview_screens.dart';

class DevGallery extends StatelessWidget {
  const DevGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = <(String, String, Widget)>[
      ('3b', 'Batch queue', const BatchQueuePreview()),
      ('3g', 'Paywall', const PaywallPreview()),
      ('3h', 'Storage setup', const StoragePreview()),
      ('4a', 'Grocery list', const GroceryPreview()),
      ('4d', 'Fair-use cap reached', const CapReachedPreview()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Design previews')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Post-alpha screens, built to the hi-fi spec. Demo data — the '
            'engines behind them land after the alpha ships.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: context.scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          for (final (id, title, screen) in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TokenCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(id, style: theme.textTheme.titleSmall)),
                  ),
                  title: Text(title, style: theme.textTheme.titleSmall),
                  trailing: Icon(Icons.chevron_right_rounded,
                      color: context.scheme.onSurfaceVariant),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => screen)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
