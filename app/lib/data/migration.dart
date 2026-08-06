// One-shot local→SAF migration for installs that saved recipes before the
// user picked a folder. Originals stay in place (cheap insurance, alpha);
// corrupt/unsavable recipes stay behind silently (§7 never-fatal stance).

import 'dart:io';

import 'app_settings.dart';
import 'recipe_store.dart';
import 'saf_store.dart';

/// Copies every readable recipe (+ images) from [from] into [to]. Returns the
/// number migrated. When [settings] is given: no-op if migrationDone is
/// already set, and sets it only after a pass with no transient failures —
/// a StoreIoException (provider hiccup) leaves the flag unset so a later
/// boot retries the stragglers; saves are idempotent, so no duplicates.
/// A GrantLostException aborts without setting the flag — re-pick, run again.
Future<int> migrateLocalToSaf(
  LocalFolderStore from,
  SafFolderStore to, {
  AppSettings? settings,
}) async {
  if (settings?.migrationDone == true) return 0;
  final result = await from.listAll();
  var migrated = 0;
  var ioFailures = 0;
  for (final recipe in result.recipes) {
    try {
      final images = <File>[];
      for (final ref in recipe.source.originalImages ?? const <String>[]) {
        final f = await from.imageFile(ref);
        if (f != null && await f.exists()) images.add(f);
      }
      await to.save(recipe, images);
      migrated++;
    } on GrantLostException {
      rethrow;
    } on StoreIoException {
      ioFailures++; // transient — must not be stranded behind the flag
    } catch (_) {} // invalid recipe: stays local for good (§7 never-fatal)
  }
  if (ioFailures == 0) await settings?.setMigrationDone(true);
  return migrated;
}
