import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/core/utils/formatters.dart';
import 'package:pothik_passenger/core/utils/phone.dart';

void main() {
  group('Formatters.currency', () {
    test('whole taka has no decimals and uses Western digits', () {
      expect(Formatters.currency(120), '৳120');
      expect(Formatters.currency(1250), '৳1,250');
    });
    test('fractional taka keeps one decimal', () {
      expect(Formatters.currency(99.5), '৳99.5');
    });
  });

  group('Formatters.distance / duration', () {
    test('meters below 1km', () {
      expect(Formatters.distance(850, bn: false), '850 m');
      expect(Formatters.distance(850, bn: true), '850 মি');
    });
    test('kilometres', () {
      expect(Formatters.distance(1200, bn: false), '1.2 km');
      expect(Formatters.distance(12400, bn: true), '12 কিমি');
    });
    test('duration never shows 0 min and rounds up', () {
      expect(Formatters.duration(10, bn: false), '1 min');
      expect(Formatters.duration(61, bn: false), '2 min');
      expect(Formatters.duration(3900, bn: false), '1 hr 5 min');
      expect(Formatters.duration(3600, bn: true), '1 ঘণ্টা');
    });
  });

  test('countdown pads mm:ss', () {
    expect(Formatters.countdown(const Duration(seconds: 30)), '00:30');
    expect(
      Formatters.countdown(const Duration(minutes: 1, seconds: 5)),
      '01:05',
    );
    expect(Formatters.countdown(const Duration(seconds: -3)), '00:00');
  });

  test('phone display and mask', () {
    expect(Formatters.phoneDisplay('+8801712345678'), '+880 1712-345678');
    expect(Formatters.phoneMasked('+8801712345678'), '+8801*******78');
  });

  test('toBanglaDigits converts only digits', () {
    expect(Formatters.toBanglaDigits('30 সেকেন্ড, ৳120'), '৩০ সেকেন্ড, ৳১২০');
  });

  group('BdPhone.normalize', () {
    test('accepts common local forms', () {
      expect(BdPhone.normalize('01712345678'), '+8801712345678');
      expect(BdPhone.normalize('1712345678'), '+8801712345678');
      expect(BdPhone.normalize('+880 1712-345678'), '+8801712345678');
      expect(BdPhone.normalize('8801712345678'), '+8801712345678');
    });
    test('accepts Bangla digits', () {
      expect(BdPhone.normalize('০১৭১২৩৪৫৬৭৮'), '+8801712345678');
    });
    test('rejects invalid operator prefixes and lengths', () {
      expect(BdPhone.normalize('01212345678'), isNull);
      expect(BdPhone.normalize('0171234567'), isNull);
      expect(BdPhone.normalize('017123456789'), isNull);
      expect(BdPhone.normalize('hello'), isNull);
    });
  });
}
