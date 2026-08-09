// Stable anonymous install id — what the extraction proxy counts the
// fair-use cap against (D2; the one piece of proxy state, context.md
// constraint 3). A UUID minted once per install, app-private, carrying no
// user identity. A lost file (reinstall, cleared data) just mints a new id
// and resets that install's count — never an error.

import 'dart:io';

import 'package:uuid/uuid.dart';

import 'atomic_file.dart';

final _shape = RegExp(r'^[A-Za-z0-9-]{8,64}$');

Future<String> loadInstallId(File file) async {
  try {
    final existing = (await file.readAsString()).trim();
    if (_shape.hasMatch(existing)) return existing;
  } catch (_) {} // missing/corrupt: mint below
  final id = const Uuid().v4();
  try {
    await writeStringAtomic(file, id);
  } catch (_) {} // best-effort: an unsaved id re-mints next boot
  return id;
}
