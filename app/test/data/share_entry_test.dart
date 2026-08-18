// ShareEntry link buffering (share-links spike): links arriving before the
// shell attaches are held, drained on attach, and buffer again after detach —
// the same never-drop contract the image path already keeps.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/share_entry.dart';

void main() {
  test('pushLink before attach is held and delivered on attach', () async {
    final entry = ShareEntry();
    entry.pushLink('https://example.com/a');

    final got = <String>[];
    await entry.attach((_) {}, onLink: got.add);
    expect(got, ['https://example.com/a']);

    entry.pushLink('https://example.com/b');
    expect(got, ['https://example.com/a', 'https://example.com/b']);
  });

  test('cold-start link drain rides attach', () async {
    final entry = ShareEntry(
        takePendingLinks: () async => ['https://example.com/cold']);
    final got = <String>[];
    await entry.attach((_) {}, onLink: got.add);
    expect(got, ['https://example.com/cold']);
  });

  test('after detach links buffer again for the next attach', () async {
    final entry = ShareEntry();
    final got = <String>[];
    await entry.attach((_) {}, onLink: got.add);
    entry.detach();

    entry.pushLink('https://example.com/later');
    expect(got, isEmpty);

    await entry.attach((_) {}, onLink: got.add);
    expect(got, ['https://example.com/later']);
  });

  test('a failed link drain never breaks attach', () async {
    final entry =
        ShareEntry(takePendingLinks: () async => throw StateError('boom'));
    await entry.attach((_) {}, onLink: (_) {});
    // Reaching here without a throw is the contract.
  });
}
