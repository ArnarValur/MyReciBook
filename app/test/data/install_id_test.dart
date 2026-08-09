// loadInstallId: mint-once stability, shape validation, corrupt re-mint.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/install_id.dart';

final _shape = RegExp(r'^[A-Za-z0-9-]{8,64}$');

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('install-id-test');
  });
  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  test('mints once, persists, reuses across loads', () async {
    final file = File('${tmp.path}/install_id');
    final id = await loadInstallId(file);
    expect(_shape.hasMatch(id), isTrue);
    expect(await loadInstallId(file), id);
    expect((await file.readAsString()).trim(), id);
  });

  test('corrupt content re-mints instead of propagating junk', () async {
    final file = File('${tmp.path}/install_id');
    await file.writeAsString('not a valid id!!!\n');
    final id = await loadInstallId(file);
    expect(_shape.hasMatch(id), isTrue);
  });
}
