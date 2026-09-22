import 'dart:math';

/// Exponential backoff with full jitter (AWS-style). Used by the realtime
/// client, polling fallback, and the location publisher.
final class BackoffPolicy {
  const BackoffPolicy({
    this.initial = const Duration(seconds: 1),
    this.max = const Duration(seconds: 30),
    this.multiplier = 2.0,
    this.maxAttempts,
  });

  final Duration initial;
  final Duration max;
  final double multiplier;

  /// `null` = unlimited.
  final int? maxAttempts;

  /// Delay before attempt number [attempt] (0-based). Deterministic when a
  /// seeded [random] is supplied (tests).
  Duration delayFor(int attempt, {Random? random}) {
    final rng = random ?? _shared;
    final capMs = min(
      max.inMilliseconds.toDouble(),
      initial.inMilliseconds * pow(multiplier, attempt),
    );
    final jittered = rng.nextDouble() * capMs;
    return Duration(milliseconds: jittered.round());
  }

  bool canRetry(int attempt) => maxAttempts == null || attempt < maxAttempts!;

  static final Random _shared = Random();
}
