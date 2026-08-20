// Starter foods — the un-barcoded door. Three curated packages (vegetables,
// fruits & berries, spices & herbs) land in the pantry as normal product
// files, pre-tagged, natural serving preselected. Foods already on the shelf
// are skipped, never overwritten (pantry_model.addStarterFoods).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/starter_foods.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'pantry_model.dart';

class StarterFoodsScreen extends StatefulWidget {
  const StarterFoodsScreen({super.key});

  @override
  State<StarterFoodsScreen> createState() => _StarterFoodsScreenState();
}

class _StarterFoodsScreenState extends State<StarterFoodsScreen> {
  bool _busy = false;

  Future<void> _import(StarterPackage pack) async {
    setState(() => _busy = true);
    final result =
        await context.read<PantryModel>().addStarterFoods(pack.foods);
    if (!mounted) return;
    setState(() => _busy = false);
    final line = result.skipped == 0
        ? '${result.added} added to your pantry'
        : '${result.added} added · ${result.skipped} already on your shelf';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(line)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final pantry = context.watch<PantryModel>();

    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Starter foods',
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontSize: 24, letterSpacing: -0.3)),
          const SizedBox(height: 6),
          Text(
            'Fresh produce and spices have no barcode to scan. These come '
            'built in — standard values for raw foods, each saved as its own '
            'file in your pantry folder. Anything already on your shelf is '
            'left alone.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 20),
          for (final pack in starterPackages) ...[
            _PackageCard(
              pack: pack,
              // "42 of 65 on your shelf" — honest count, live per build.
              onShelf: pack.foods
                  .where((f) => pantry.byId(f.toProduct().id) != null)
                  .length,
              busy: _busy,
              onImport: () => _import(pack),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard(
      {required this.pack,
      required this.onShelf,
      required this.busy,
      required this.onImport});

  final StarterPackage pack;
  final int onShelf;
  final bool busy;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final total = pack.foods.length;
    final allIn = onShelf >= total;
    // A taste of what's inside, not the whole list.
    final preview =
        pack.foods.take(4).map((f) => f.name).join(', ');

    return TokenCard(
      radius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(pack.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(pack.name,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Text(
              onShelf == 0 ? '$total foods' : '$onShelf of $total on shelf',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ]),
          const SizedBox(height: 8),
          Text('$preview…',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.4)),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: busy || allIn ? null : onImport,
            child: Text(allIn ? 'All on your shelf' : 'Add all $total'),
          ),
        ],
      ),
    );
  }
}
