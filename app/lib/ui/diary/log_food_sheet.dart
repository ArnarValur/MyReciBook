// The log sheet — MFP's food detail page: pick a serving, say how many, watch
// the numbers move, log it. The one screen where an entry's snapshot is made.
//
// Every product offers its own portions plus 100 g plus a typed gram amount,
// so a pack that never declared a serving is still loggable and a loose apple
// can be weighed.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/nutrient_display.dart';
import '../../domain/product.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'diary_model.dart';
import 'diary_tab.dart' show parseAmount;

/// Returns true when something was logged.
Future<bool?> showLogFoodSheet(
  BuildContext context, {
  required Product product,
  required String meal,
}) {
  final diary = context.read<DiaryModel>();
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider<DiaryModel>.value(
      value: diary,
      child: _LogFoodSheet(product: product, meal: meal),
    ),
  );
}

class _LogFoodSheet extends StatefulWidget {
  const _LogFoodSheet({required this.product, required this.meal});

  final Product product;
  final String meal;

  @override
  State<_LogFoodSheet> createState() => _LogFoodSheetState();
}

class _LogFoodSheetState extends State<_LogFoodSheet> {
  late Serving _serving;
  late String _meal;
  final _amount = TextEditingController(text: '1');
  final _grams = TextEditingController();

  /// True while the user is typing a gram weight instead of picking a
  /// declared portion — MFP's "custom serving" state.
  bool _byWeight = false;

  @override
  void initState() {
    super.initState();
    _serving = widget.product.preferredServing;
    _meal = widget.meal;
  }

  @override
  void dispose() {
    _amount.dispose();
    _grams.dispose();
    super.dispose();
  }

  double get _quantity {
    if (_byWeight) return 1;
    return parseAmount(_amount.text) ?? 0;
  }

  /// The portion actually being logged: a declared one, or the typed weight.
  Serving? get _chosen {
    if (!_byWeight) return _serving;
    final grams = parseAmount(_grams.text);
    if (grams == null || grams <= 0) return null;
    return Serving.grams(grams);
  }

  bool get _canLog {
    final serving = _chosen;
    return serving != null && _quantity > 0;
  }

  Future<void> _log() async {
    final serving = _chosen;
    if (serving == null || _quantity <= 0) return;
    await context.read<DiaryModel>().logProduct(
          widget.product,
          serving,
          meal: _meal,
          quantity: _quantity,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final diary = context.watch<DiaryModel>();
    final product = widget.product;
    final serving = _chosen;
    final per100 = product.nutriments ?? Nutriments();
    final logged = serving == null
        ? Nutriments()
        : per100.scaled(serving.grams / 100 * _quantity);
    final insets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        // The CTA is pinned, not the last row of the scroll: on an S21 the
        // nutrition card already fills the sheet, and a button you have to
        // find by scrolling is a button people miss.
        builder: (_, controller) => Column(children: [
          Expanded(
              child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
            Text(product.name,
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontSize: 22, letterSpacing: -0.3)),
            if ((product.brand ?? '').isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(product.brand!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 18),

            const SectionLabel('Serving'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in product.servingOptions)
                  _Choice(
                    label: option.label,
                    selected: !_byWeight && option.label == _serving.label,
                    onTap: () => setState(() {
                      _byWeight = false;
                      _serving = option;
                    }),
                  ),
                _Choice(
                  label: 'Weigh it',
                  selected: _byWeight,
                  onTap: () => setState(() => _byWeight = true),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_byWeight)
              TextField(
                controller: _grams,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                    labelText: 'Grams', suffixText: 'g'),
              )
            else
              TextField(
                controller: _amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                    labelText: 'How many',
                    helperText: '× ${_serving.label}'),
              ),
            const SizedBox(height: 20),

            const SectionLabel('Meal'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in diary.mealNames)
                  _Choice(
                    label: name,
                    selected: name == _meal,
                    onTap: () => setState(() => _meal = name),
                  ),
              ],
            ),
            const SizedBox(height: 22),

            TokenCard(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text((logged.kcal ?? 0).round().toString(),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontSize: 30, letterSpacing: -0.8)),
                    const SizedBox(width: 5),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('kcal',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ),
                    const Spacer(),
                    if (serving != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${(serving.grams * _quantity).round()} g',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                  ]),
                  if (per100.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This food has no nutrition on file yet. It will log as '
                      'an amount with no numbers behind it.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant, height: 1.5),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      for (final key in const ['fat', 'carbs', 'protein'])
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  key == 'carbs'
                                      ? 'Carbs'
                                      : nutrientLabel(key),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurfaceVariant)),
                              const SizedBox(height: 2),
                              Text('${(logged[key] ?? 0).round()} g',
                                  style: theme.textTheme.titleSmall),
                            ],
                          ),
                        ),
                    ]),
                  ],
                ],
              ),
            ),
            ],
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _canLog ? _log : null,
                icon: const Icon(Icons.add_rounded),
                // The meal name as the user wrote it — and distinct from the
                // picker's lowercase title behind it.
                label: Text('Add to $_meal'),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A selectable pill — MetaChip's look with a selected state, kept local
/// because nothing else in the app needs a choice chip yet.
class _Choice extends StatelessWidget {
  const _Choice(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface),
        ),
      ),
    );
  }
}
