// One-shot local→SAF migration for installs that saved recipes before the
// user picked a folder. Originals stay in place (cheap insurance, alpha);
// corrupt/unsavable recipes stay behind silently (§7 never-fatal stance).
//
// The pantry migration below is copy-VERIFY-delete instead: the old
// app-private docs/pantry dir is drained into <tree>/pantry/, each file
// removed only after its SAF copy read back correct, so an interrupted run
// resumes from whatever is still in the old dir (idempotent — the stem IS
// the identity, a re-copy overwrites its own file).

import 'dart:convert';
import 'dart:io';

import '../domain/product.dart';
import 'app_settings.dart';
import 'product_store.dart';
import 'recipe_store.dart';
import 'saf_pantry_store.dart';
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

/// Moves every valid product (+ photo) from the app-private [from] into the
/// SAF-backed [to]. Per product: copy, read back and verify, only then
/// delete the old files (photo first, then JSON — a crash between the two
/// leaves the JSON to re-run, never a JSON whose photo is gone from both
/// sides). Old dirs are removed only once empty, so foreign/corrupt files
/// are never destroyed (§7). No done-flag: an emptied old dir IS the flag,
/// and a partial pass retries whatever it left on the next boot.
/// A GrantLostException aborts mid-pass — re-pick, run again.
/// Returns the number of products moved this pass.
Future<int> migratePantryToSaf(LocalPantryStore from, SafPantryStore to) async {
  if (!await from.root.exists()) return 0;
  final result = await from.listAll();
  var migrated = 0;
  for (final product in result.products) {
    try {
      final oldImage = from.imageFile(product);
      final oldImageBytes = oldImage != null && await oldImage.exists()
          ? await oldImage.readAsBytes()
          : null;
      final Product saved;
      if (oldImageBytes != null) {
        saved = await to.attachImage(product, oldImage!);
      } else {
        saved = await to.save(product);
      }
      // Verify the SAF copy by reading it back before touching the old files.
      final back = await to.load(saved.id);
      if (back == null ||
          jsonEncode(back.toJson()) != jsonEncode(saved.toJson())) {
        continue; // stays in the old dir for the next boot
      }
      if (oldImageBytes != null) {
        final landed = await to.imageBytes(saved);
        if (landed == null || !_sameBytes(landed, oldImageBytes)) continue;
        await oldImage!.delete();
      }
      final oldJson = File('${from.root.path}/${product.id}.json');
      if (await oldJson.exists()) await oldJson.delete();
      final tmp = File('${oldJson.path}.tmp');
      if (await tmp.exists()) await tmp.delete();
      migrated++;
    } on GrantLostException {
      rethrow;
    } on StoreIoException {
      // transient — the old files are untouched, a later boot retries
    } catch (_) {} // unreadable original: stays local for good (§7)
  }
  await _removeIfEmpty(Directory('${from.root.path}/images'));
  await _removeIfEmpty(from.root);
  return migrated;
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<void> _removeIfEmpty(Directory dir) async {
  if (await dir.exists() && await dir.list().isEmpty) await dir.delete();
}
