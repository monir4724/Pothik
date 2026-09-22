import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/logging/app_logger.dart';

void main() {
  test('scrubs BD phone numbers', () {
    expect(
      AppLogger.scrub('otp for +8801712345678 sent'),
      'otp for +880****78 sent',
    );
    expect(AppLogger.scrub('user 01712345678'), 'user 0171****78');
  });

  test('truncates coordinates to ~1km precision', () {
    expect(AppLogger.scrub('at 23.792512,90.407811'), 'at 23.792x,90.407x');
  });

  test('redacts bearer tokens', () {
    expect(
      AppLogger.scrub('Authorization: Bearer eyJhbGciOi.abc.def'),
      'Authorization: Bearer [redacted]',
    );
  });
}
