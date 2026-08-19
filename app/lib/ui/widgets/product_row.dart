// The ONE pantry product card (Arnar, 2026-08-19: the picker had grown its
// own lookalike without the photo — same purpose, same card). Used by the
// Pantry list and the diary's Add-food picker; change it here, both follow.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/product.dart';
import '../theme.dart';
import 'skin.dart';

class ProductRow extends StatelessWidget {
  const ProductRow({
    super.key,
    required this.product,
    this.imageFile,
    required this.onTap,
    this.onLongPress,
  });

  final Product product;

  /// The user's own photo, resolved by the caller (PantryModel.imageFileOf) —
  /// the widget stays synchronous and store-free.
  final File? imageFile;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = context.scheme;
    final kcal = product.nutriments?.kcal;
    final meta = [
      if ((product.brand ?? '').isNotEmpty) product.brand!,
      if ((product.quantity ?? '').isNotEmpty) product.quantity!,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TokenCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Row(children: [
            if (imageFile != null && imageFile!.existsSync())
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(imageFile!,
                    width: 38, height: 38, fit: BoxFit.cover, cacheWidth: 114),
              )
            else
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.kitchen_rounded,
                    size: 20, color: scheme.onSecondaryContainer),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  if (meta.isNotEmpty)
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (kcal != null) ...[
              const SizedBox(width: 8),
              MetaChip(label: '${kcal.round()} kcal'),
            ],
          ]),
        ),
      ),
    );
  }
}
