import 'package:intl/intl.dart';

/// Digit-rendering rule (production UI review §5), applied consistently:
///
/// - **Western digits (0-9)** for anything the user scans or types:
///   fare, OTP, countdown, distance, ETA, phone numbers, dates in lists.
/// - **Bangla digits (০-৯)** are allowed only inside prose sentences, via
///   [Formatters.toBanglaDigits], and only when locale is `bn`.
abstract final class Formatters {
  static const String takaSign = '৳';

  static const List<String> _banglaDigits = [
    '০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯', //
  ];

  /// `৳120` — no decimals for whole taka, one decimal otherwise, thousands
  /// separator always. Western digits by rule.
  static String currency(num amount) {
    final isWhole = amount == amount.roundToDouble();
    final f = NumberFormat(isWhole ? '#,##0' : '#,##0.0', 'en_US');
    return '$takaSign${f.format(amount)}';
  }

  /// `1.2 km` / `850 m` for [meters].
  static String distance(int meters, {required bool bn}) {
    if (meters < 1000) {
      return bn ? '$meters মি' : '$meters m';
    }
    final km = meters / 1000;
    final s = km >= 10 ? km.toStringAsFixed(0) : km.toStringAsFixed(1);
    return bn ? '$s কিমি' : '$s km';
  }

  /// `12 min` / `1 hr 5 min` for [seconds]. Rounds up; never shows `0 min`.
  static String duration(int seconds, {required bool bn}) {
    final minutes = (seconds / 60).ceil().clamp(1, 1 << 30);
    if (minutes < 60) {
      return bn ? '$minutes মিনিট' : '$minutes min';
    }
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (bn) {
      return m == 0 ? '$h ঘণ্টা' : '$h ঘণ্টা $m মিনিট';
    }
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  /// `00:30` style countdown.
  static String countdown(Duration d) {
    final total = d.inSeconds.clamp(0, 359999);
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// `+880 17XX-XXXXXX` display form for a normalised `+8801XXXXXXXXX`.
  static String phoneDisplay(String e164) {
    if (!e164.startsWith('+880') || e164.length != 14) return e164;
    final local = e164.substring(4); // 10 digits, starts with 1
    return '+880 ${local.substring(0, 4)}-${local.substring(4)}';
  }

  /// Masked form for logs / receipts: `+8801*******89`.
  static String phoneMasked(String e164) {
    if (e164.length < 6) return '***';
    return '${e164.substring(0, 5)}${'*' * (e164.length - 7)}'
        '${e164.substring(e164.length - 2)}';
  }

  static String date(DateTime dt, {required String locale}) =>
      DateFormat.yMMMd(locale).format(dt);

  static String time(DateTime dt, {required String locale}) =>
      DateFormat.jm(locale).format(dt);

  static String dateTime(DateTime dt, {required String locale}) =>
      '${date(dt, locale: locale)} · ${time(dt, locale: locale)}';

  /// Converts Western digits in [input] to Bangla digits. Prose only.
  static String toBanglaDigits(String input) {
    final buf = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x30 && rune <= 0x39) {
        buf.write(_banglaDigits[rune - 0x30]);
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  /// `4.8` rating display; hides trailing `.0`.
  static String rating(double r) =>
      r == r.roundToDouble() ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
}
