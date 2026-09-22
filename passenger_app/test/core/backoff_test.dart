import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/network/retry_policy.dart';

void main() {
  test('delay is bounded by exponential cap and max', () {
    const p = BackoffPolicy(max: Duration(seconds: 10));
    final rng = Random(1);
    for (var attempt = 0; attempt < 10; attempt++) {
      final d = p.delayFor(attempt, random: rng);
      final cap = min(10000, 1000 * pow(2, attempt)).toInt();
      expect(d.inMilliseconds, inInclusiveRange(0, cap));
    }
  });

  test('jitter is applied (not all delays equal)', () {
    const p = BackoffPolicy();
    final rng = Random(7);
    final ds = List.generate(
      5,
      (_) => p.delayFor(3, random: rng).inMilliseconds,
    );
    expect(ds.toSet().length, greaterThan(1));
  });

  test('maxAttempts gates retries', () {
    const p = BackoffPolicy(maxAttempts: 3);
    expect(p.canRetry(2), isTrue);
    expect(p.canRetry(3), isFalse);
    expect(const BackoffPolicy().canRetry(999), isTrue);
  });
}
