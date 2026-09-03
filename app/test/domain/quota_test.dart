// QuotaSnapshot derivations the import sheet and the cap screen lean on
// (docs/ai-cap-mechanics.md §2): "left" never negative, "exhausted" only
// when the grant is really spent, the ~80% heads-up exactly once.

import 'package:flutter_test/flutter_test.dart';
import 'package:myrecibook/domain/quota.dart';

void main() {
  test('left counts down and never goes negative', () {
    expect(const QuotaSnapshot(used: 487, cap: 1200).left, 713);
    expect(const QuotaSnapshot(used: 1200, cap: 1200).left, 0);
    // A cap lowered under existing spending reads as empty, not "-5 left".
    expect(const QuotaSnapshot(used: 1205, cap: 1200).left, 0);
  });

  test('exhausted only when the grant is spent', () {
    expect(const QuotaSnapshot(used: 1199, cap: 1200).exhausted, isFalse);
    expect(const QuotaSnapshot(used: 1200, cap: 1200).exhausted, isTrue);
    expect(const QuotaSnapshot(used: 1300, cap: 1200).exhausted, isTrue);
    // No cap at all is not "spent".
    expect(const QuotaSnapshot(used: 0, cap: 0).exhausted, isFalse);
  });

  test('the heads-up window opens at 80% and closes at empty', () {
    expect(const QuotaSnapshot(used: 959, cap: 1200).nearlyUsed, isFalse);
    expect(const QuotaSnapshot(used: 960, cap: 1200).nearlyUsed, isTrue);
    expect(const QuotaSnapshot(used: 1199, cap: 1200).nearlyUsed, isTrue);
    expect(const QuotaSnapshot(used: 1200, cap: 1200).nearlyUsed, isFalse);
    expect(const QuotaSnapshot(used: 0, cap: 0).nearlyUsed, isFalse);
  });
}
