// Pure-Dart SHA-256 against FIPS 180-4 / NIST known-answer vectors — this is
// what makes bundling the hash (instead of package:crypto) safe.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/data/sha256.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('empty input', () {
    expect(
      _hex(sha256(const [])),
      'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    );
  });

  test('"abc"', () {
    expect(
      _hex(sha256(ascii.encode('abc'))),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('two-block message (56 bytes forces length into a second block)', () {
    expect(
      _hex(sha256(ascii.encode(
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'))),
      '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
    );
  });

  test('one million "a" (long-input vector)', () {
    expect(
      _hex(sha256(List.filled(1000000, 0x61))),
      'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0',
    );
  });
}
