// The product page — the file IS the form (design 1c). The overview and the
// old "Edit food" screen were 50/50 duplicates of each other: the same seven
// macros, once read-only and once typed. They are one page now. Every value
// edits where it is shown, there is no "Edit this product" door and no Save
// button — back saves and the header ticks "saved", because this is the
// user's own file and there is nothing to confirm.
//
// Autosave is debounced, and it only ever writes when something was actually
// typed: opening a product and touching nothing must not mark the file as
// hand-edited (that flag is what keeps the bulk refresh off it).
//
// The one thing that cannot be written mid-keystroke is a rename. A
// barcode-less product's filename is its name slug, so "Appl" → "Apple" is
// two files, not one edit; renames are held back to the leaving flush and
// done as a real move (see [_renameTo]).

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/nutrient_display.dart';
import '../../domain/product.dart';
import '../../domain/product_categories.dart';
import '../photo_sources.dart';
import '../theme.dart';
import '../widgets/skin.dart';
import 'manual_product_screen.dart' show ProductTagCloud, askForOwnTag;
import 'pantry_model.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key, required this.productId});

  /// By id, not value: the page re-reads the model on every notify, so a
  /// photo swap or an Open Food Facts refresh lands live under the fields.
  final String productId;

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  /// Long enough that a typed word is one write, short enough that "saved"
  /// is true by the time a thumb reaches the back arrow.
  static const _autosave = Duration(milliseconds: 700);

  /// The file this page is bound to. Not final: a rename moves it.
  late String _id;

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _size = TextEditingController();
  final _portionLabel = TextEditingController();
  final _portionGrams = TextEditingController();

  /// The nutrition rows are frozen at load, not derived from the live
  /// product. Deriving them would delete a row from under the cursor the
  /// moment its field went blank, and would swap g for mg mid-typing.
  var _macroFields = <_NutrientField>[];
  var _extraFields = <_NutrientField>[];

  /// What the portion fields held when they were loaded — an untouched
  /// portion is left exactly as the file has it, extra servings included.
  String _loadedPortionLabel = '';
  String _loadedPortionGrams = '';

  bool _dirty = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _id = widget.productId;
    final product = context.read<PantryModel>().byId(_id);
    if (product != null) _load(product);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _brand.dispose();
    _size.dispose();
    _portionLabel.dispose();
    _portionGrams.dispose();
    for (final f in [..._macroFields, ..._extraFields]) {
      f.controller.dispose();
    }
    super.dispose();
  }

  /// Fields ← file. Called once on open and again after an Open Food Facts
  /// refresh, which is the only thing allowed to overwrite typed values.
  void _load(Product product) {
    _name.text = product.name;
    _brand.text = product.brand ?? '';
    _size.text = product.quantity ?? '';
    final portion = product.servings.isEmpty ? null : product.servings.first;
    _portionLabel.text = portion?.label ?? '';
    _portionGrams.text = portion == null ? '' : _trim(portion.grams);
    _loadedPortionLabel = _portionLabel.text;
    _loadedPortionGrams = _portionGrams.text;

    for (final f in [..._macroFields, ..._extraFields]) {
      f.controller.dispose();
    }
    final values = product.nutriments?.values ?? const <String, double>{};
    _macroFields = [
      for (final key in Nutriments.macroKeys) _NutrientField(key, values[key])
    ];
    _extraFields = [
      for (final key in product.nutriments?.extraKeys ?? const <String>[])
        _NutrientField(key, values[key])
    ];
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  static double? _parse(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Something was typed: the header goes honest and the write is queued.
  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
    _timer?.cancel();
    _timer = Timer(_autosave, () {
      _timer = null;
      unawaited(_write(rename: false));
    });
  }

  /// Everything still pending goes to disk. Back waits for this — "the header
  /// ticks saved" is a promise, not a hope.
  Future<void> _flush() async {
    _timer?.cancel();
    _timer = null;
    // A name typed to nothing is not an edit anyone meant: the validator
    // refuses an empty name anyway, so the stored one comes back.
    if (_name.text.trim().isEmpty) {
      final current = context.read<PantryModel>().byId(_id);
      if (current != null) _name.text = current.name;
    }
    if (!_dirty) return;
    await _write(rename: true);
  }

  Future<void> _write({required bool rename}) async {
    final model = context.read<PantryModel>();
    final current = model.byId(_id);
    if (current == null) return;
    final next = _assemble(current);
    if (next.id != current.id) {
      // Half a typed name must not leave half a pantry behind.
      if (!rename) return;
      await _renameTo(model, current, next);
    } else {
      await model.upsert(next);
    }
    if (!mounted) return;
    setState(() => _dirty = false);
  }

  /// A rename is a move, not a save: the stem changed, so the new file is
  /// written, the photo is carried over to the new stem, and only then does
  /// the old file go — otherwise the shelf ends up holding both.
  Future<void> _renameTo(PantryModel model, Product old, Product next) async {
    final photo = model.imageFileOf(old);
    final saved = await model.upsert(next.copyWith(clearImage: true));
    _id = saved.id;
    if (photo != null && photo.existsSync()) {
      await model.attachImage(saved, photo);
    }
    await model.remove(old.id);
  }

  /// The fields as a product file. Untouched values are carried across
  /// verbatim rather than re-parsed — a value nobody edited must come out of
  /// a save bit-for-bit as it went in.
  Product _assemble(Product p) {
    final name = _name.text.trim();
    final brand = _brand.text.trim();
    final size = _size.text.trim();

    final values = <String, double>{};
    for (final f in [..._macroFields, ..._extraFields]) {
      final typed = f.controller.text;
      if (typed == f.loaded) {
        // Blank stays blank: an untyped field is "not measured", never a 0.
        if (f.stored != null) values[f.key] = f.stored!;
        continue;
      }
      final v = _parse(typed);
      if (v != null) values[f.key] = v * f.gramsPerUnit;
    }

    // The portion is only rebuilt when it was actually touched, so a product
    // carrying several servings keeps the rest of them.
    var servings = p.servings;
    if (_portionLabel.text != _loadedPortionLabel ||
        _portionGrams.text != _loadedPortionGrams) {
      final grams = _parse(_portionGrams.text);
      final label = _portionLabel.text.trim();
      final rest = p.servings.skip(1);
      servings = [
        if (grams != null && grams > 0)
          Serving(label: label.isEmpty ? '1 portion' : label, grams: grams),
        ...rest,
      ];
    }

    return p.copyWith(
      name: name.isEmpty ? null : name,
      brand: brand.isEmpty ? null : brand,
      clearBrand: brand.isEmpty,
      quantity: size.isEmpty ? null : size,
      clearQuantity: size.isEmpty,
      nutriments: values.isEmpty && p.nutriments == null
          ? null
          : Nutriments.fromMap(values),
      servings: servings,
      defaultServing: servings.isEmpty ? null : 0,
    );
  }

  Future<void> _pick(Product product, Future<List<File>> Function() source) async {
    final model = context.read<PantryModel>();
    final photo = await context.read<PhotoSources>().pickOne(source);
    if (photo == null) return;
    final old = model.imageFileOf(product);
    await model.attachImage(product, photo);
    // Same path, new bytes: evict or the cache shows the old photo.
    if (old != null) await FileImage(old).evict();
    final fresh = model.byId(_id);
    final file = fresh == null ? null : model.imageFileOf(fresh);
    if (file != null) await FileImage(file).evict();
  }

  Future<void> _photoSheet(Product product) async {
    final photos = context.read<PhotoSources>();
    final model = context.read<PantryModel>();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (photos.camera != null)
            ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, 'camera')),
          ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('From gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery')),
          if (product.image != null)
            ListTile(
                leading:
                    Icon(Icons.delete_outline_rounded, color: ctx.scheme.error),
                title: const Text('Remove photo'),
                onTap: () => Navigator.pop(ctx, 'remove')),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'camera':
        await _pick(product, photos.camera!);
      case 'gallery':
        await _pick(product, photos.gallery);
      case 'remove':
        await model.removeImage(product);
    }
  }

  /// "+ Add tag" — the create screen's own tag cloud, lifted into a sheet so
  /// the two doors offer one vocabulary. Every tap saves immediately and on
  /// its own path: shelving a product is not a data correction, so it must
  /// not mark the file hand-edited and shield it from the bulk refresh
  /// (Arnar, 2026-08-19).
  Future<void> _tagSheet() async {
    final model = context.read<PantryModel>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final tags = model.byId(_id)?.tags ?? const <String>[];
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Tags'),
                    const SizedBox(height: 10),
                    ProductTagCloud(
                      selected: tags,
                      onToggle: (tag) async {
                        final next = tags.contains(tag)
                            ? [
                                for (final t in tags)
                                  if (t != tag) t
                              ]
                            : [...tags, tag];
                        await model.setTags(_id, next);
                        setSheet(() {});
                      },
                      onAddOwn: () async {
                        final tag = await askForOwnTag(ctx);
                        if (tag == null || tags.contains(tag)) return;
                        await model.setTags(_id, [...tags, tag]);
                        setSheet(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The one path that lets the crowd overwrite typed values, and it is a
  /// button the user presses. A hand-edited file says what it is about to
  /// lose first; afterwards the fields are re-read from what landed.
  Future<void> _refreshFromOff(Product product) async {
    final model = context.read<PantryModel>();
    if (product.userEdited) {
      final ok = await showDestructiveConfirm(
        context,
        title: 'Replace your edits?',
        body: 'Your photo and tags stay. The name, brand and nutrition you '
            'typed are overwritten with whatever Open Food Facts has now, '
            'and the edited-by-hand mark is cleared.',
        verb: 'Replace',
      );
      if (!ok || !mounted) return;
    }
    // Pending keystrokes are exactly what the user just agreed to lose.
    _timer?.cancel();
    _timer = null;
    setState(() => _dirty = false);
    final outcome = await model.refreshOne(_id);
    if (!mounted) return;
    final String line;
    switch (outcome) {
      case PantryAdded(product: final fresh):
        setState(() => _load(fresh));
        line = 'Updated from Open Food Facts';
      case PantryNotFound():
        line = 'No longer on Open Food Facts — your copy is kept as it is';
      case PantryUnavailable():
        line = 'Open Food Facts didn\'t answer — try again';
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(line)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final model = context.watch<PantryModel>();
    final product = model.byId(_id);
    if (product == null) {
      // Removed while this route was open — honest empty, not a crash.
      return Scaffold(
          appBar: AppBar(leading: const AppBackButton()),
          body: const Center(child: Text('This product was removed.')));
    }
    final imageFile = model.imageFileOf(product);
    final hasImage = imageFile != null && imageFile.existsSync();
    // Where this file came from — the old edit screen's promise, moved into
    // the footer now that the screen it lived on is gone.
    final provenance = product.barcode.isEmpty
        ? 'Your own entry'
        : 'From Open Food Facts · barcode ${product.barcode}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _flush();
        nav.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          actions: [
            Row(children: [
              Text(_dirty ? 'saving…' : 'saved',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(width: 6),
              Icon(
                _dirty ? Icons.sync_rounded : Icons.check_circle_rounded,
                size: 18,
                color: _dirty ? scheme.onSurfaceVariant : scheme.primary,
              ),
              const SizedBox(width: 16),
            ]),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // The user's own photo of the product; tap to add/replace/remove.
            if (hasImage)
              GestureDetector(
                onTap: () => _photoSheet(product),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(imageFile,
                      height: 180, fit: BoxFit.cover, cacheWidth: 1080),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () => _photoSheet(product),
                icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                label: const Text('Add your photo'),
              ),
            const SizedBox(height: 16),

            // Name — the pencil is an affordance, not a button: the field
            // under it is already live.
            const SectionLabel('Name'),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  key: const Key('product-name'),
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _touch(),
                  decoration: _lineDecoration(context),
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Icon(Icons.edit_rounded,
                    size: 15, color: scheme.onSurfaceVariant),
              ),
            ]),
            const SizedBox(height: 14),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Brand or shop'),
                    TextField(
                      key: const Key('product-brand'),
                      controller: _brand,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => _touch(),
                      decoration: _lineDecoration(context),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Size'),
                    TextField(
                      key: const Key('product-size'),
                      controller: _size,
                      onChanged: (_) => _touch(),
                      decoration: _lineDecoration(context, hint: '400 ml'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            // Shelving, right here on the product — the chips ARE the tags,
            // and the one door adds another.
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final tag in product.tags)
                _TagChip(label: categoryLabel(tag), onTap: _tagSheet),
              _AddTagChip(onTap: _tagSheet),
            ]),
            const SizedBox(height: 16),

            TokenCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const Expanded(child: SectionLabel('A portion')),
                _QuietWord('called'),
                SizedBox(
                  width: 62,
                  child: TextField(
                    key: const Key('portion-label'),
                    controller: _portionLabel,
                    textAlign: TextAlign.center,
                    onChanged: (_) => _touch(),
                    decoration: _lineDecoration(context, hint: '1 dl'),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                _QuietWord('weighs'),
                SizedBox(
                  width: 46,
                  child: TextField(
                    key: const Key('portion-grams'),
                    controller: _portionGrams,
                    textAlign: TextAlign.center,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _touch(),
                    decoration: _lineDecoration(context),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 4),
                _QuietWord('g'),
              ]),
            ),
            const SizedBox(height: 12),

            TokenCard(
              radius: 16,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Per 100 g'),
                  const SizedBox(height: 2),
                  Text(
                    'Straight off the label. Blank means "not measured", '
                    'not zero.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.3),
                  ),
                  const SizedBox(height: 2),
                  for (final f in _macroFields)
                    _NutrientLine(
                      field: f,
                      last: f == _macroFields.last,
                      onChanged: _touch,
                    ),
                ],
              ),
            ),

            // Only the products that actually carry vitamins get the card —
            // an empty one would be a row of blanks nobody can fill from a
            // pack that doesn't print them.
            if (_extraFields.isNotEmpty) ...[
              const SizedBox(height: 12),
              TokenCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Vitamins and minerals'),
                    const SizedBox(height: 2),
                    for (final f in _extraFields)
                      _NutrientLine(
                        field: f,
                        last: f == _extraFields.last,
                        onChanged: _touch,
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Explicit, never automatic: the crowd does not get to overwrite
            // typed values behind the user's back. Hidden on barcode-less
            // foods — there is nothing to look up.
            if (product.barcode.isNotEmpty)
              OutlinedButton.icon(
                onPressed:
                    model.busy ? null : () => _refreshFromOff(product),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Update from Open Food Facts'),
              ),
            const SizedBox(height: 14),
            Text(
              '$provenance. What you type here wins, and stays yours. '
              'Saved as its own file in your pantry folder.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hairline every editable value sits on — the mockup's single rule for
/// "this is typed into", thickened in primary while it has the cursor.
InputDecoration _lineDecoration(BuildContext context, {String? hint}) {
  final scheme = context.scheme;
  return InputDecoration(
    isDense: true,
    hintText: hint,
    contentPadding: const EdgeInsets.only(bottom: 4),
    enabledBorder: UnderlineInputBorder(
      borderSide:
          BorderSide(color: scheme.outline.withValues(alpha: 0.45)),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: scheme.primary, width: 1.5),
    ),
  );
}

/// The small grey words that turn a row of fields into a sentence —
/// "called ___ weighs ___ g".
class _QuietWord extends StatelessWidget {
  const _QuietWord(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: context.scheme.onSurfaceVariant)),
      );
}

/// One editable nutrient: its stored value, the unit it is READ in, and the
/// text it was loaded with.
///
/// Storage is grams (kcal aside), but [formatNutrient] steps a trace amount
/// down to mg or µg so nobody counts leading zeros — and what is on screen is
/// what gets typed into. The unit is therefore fixed for the life of the
/// page: recomputing it per keystroke would swap g for mg under the cursor.
class _NutrientField {
  _NutrientField(this.key, this.stored)
      : unit = stored == null
            ? (key == 'kcal' ? 'kcal' : 'g')
            : formatNutrient(key, stored).$2,
        loaded = stored == null ? '' : formatNutrient(key, stored).$1 {
    controller = TextEditingController(text: loaded);
  }

  final String key;

  /// What the file holds, or null when this nutrient was never measured.
  final double? stored;

  final String unit;

  /// The text [controller] started with — an untouched field writes [stored]
  /// back verbatim rather than re-parsing it, so a value nobody edited cannot
  /// drift by a floating-point hair.
  final String loaded;

  late final TextEditingController controller;

  /// The multiplier from the displayed unit back to storage.
  double get gramsPerUnit => switch (unit) {
        'mg' => 0.001,
        'µg' => 0.000001,
        _ => 1, // g, and the units that are their own (kcal, kJ)
      };
}

/// One line of a nutrition card: name, the value typed on its own hairline,
/// and the unit it is read in.
class _NutrientLine extends StatelessWidget {
  const _NutrientLine(
      {required this.field, required this.last, required this.onChanged});

  final _NutrientField field;
  final bool last;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: context.rb.separator))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(nutrientLabel(field.key),
                style: theme.textTheme.bodyMedium?.copyWith(
                    // The "— of which" lines are subordinate on a label and
                    // read that way here too.
                    color: nutrientLabel(field.key).startsWith('—')
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface)),
          ),
        ),
        SizedBox(
          width: 56,
          child: TextField(
            key: Key('nutrient-${field.key}'),
            controller: field.controller,
            textAlign: TextAlign.right,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => onChanged(),
            decoration: _lineDecoration(context),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(field.unit,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant)),
          ),
        ),
      ]),
    );
  }
}

/// A tag the product wears. Filled, because on this page a chip is a fact
/// about the file and not a filter waiting to be switched on.
class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onTap});

  final String label;
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
          color: scheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600, color: scheme.onPrimary)),
      ),
    );
  }
}

/// The door that adds one — outlined so it reads as an action beside the
/// filled facts, never as a tag called "Add tag".
class _AddTagChip extends StatelessWidget {
  const _AddTagChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      key: const Key('product-add-tag'),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.7), width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 15, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text('Add tag',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant)),
        ]),
      ),
    );
  }
}
