repo: ArnarValur/MyReciBook
branch: main

## Last sync
date: 2026-08-21T09:05:00Z

### Updated in this project
- Re-normalized against the reviewed as-built DESIGN.md (v0.10.0+8): no info color, semantic contrast rules, cover gradients, slot-3 nav
- LogoMark ported 1:1 from app/lib/ui/widgets/logo_mark.dart; RecipeCover with title-hash gradients from skin.dart
- New components from widgets/: CategoryChipRow, ServingsStepper, DurationField, CoverPickerField, ProductRow, AppBackButton
- Spec archived at guidelines/DESIGN-as-built.md

## Sync history
- 2026-08-06T15:18:48Z — initial build: fonts bundled, tokens from theme.dart + handoff.md, 19 components from skin.dart / glass_nav_bar.dart

## Screen map
| Project file | Repo source |
|---|---|
| tokens/*.css | app/lib/ui/theme.dart, DESIGN.md (as-built spec) |
| components/brand/LogoMark | app/lib/ui/widgets/logo_mark.dart |
| components/forms/* | app/lib/ui/theme.dart (button themes), widgets/category_chips.dart, import_sheet.dart, settings_tab.dart |
| components/editor/* | app/lib/ui/widgets/editor_fields.dart |
| components/surfaces/* | app/lib/ui/widgets/skin.dart |
| components/data-display/* | app/lib/ui/widgets/skin.dart (RecipeCover, qtyBoldSpan), widgets/product_row.dart, recipe_list_screen.dart |
| components/navigation/* | app/lib/ui/widgets/glass_nav_bar.dart, skin.dart (GradientFab, AppBackButton), app_shell.dart |
| components/feedback/* | app/lib/ui/widgets/skin.dart (showDestructiveConfirm), theme.dart (snackbar) |
| guidelines/DESIGN-as-built.md | DESIGN.md (user-reviewed copy) |
| assets/fonts/* | app/google_fonts/* |
