import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/version.dart';

// Guards the hand-mirror: pubspec.yaml's `version:` is the single source of
// truth; kAppVersion must match its build-name part (before the +N).
void main() {
  test('kAppVersion matches pubspec version', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match =
        RegExp(r'^version:\s*(\S+?)\+(\d+)\s*$', multiLine: true).firstMatch(pubspec);
    expect(match, isNotNull,
        reason: 'pubspec.yaml must declare version: X.Y.Z+N');
    expect(kAppVersion, match!.group(1),
        reason: 'lib/version.dart kAppVersion drifted from pubspec.yaml — '
            'update both together');
  });
}
