/// Bangladeshi mobile number handling.
///
/// Accepts the forms real users type — `01712345678`, `1712345678`,
/// `+8801712345678`, `8801712345678`, with spaces/dashes — and normalises to
/// E.164 `+8801712345678`. Bangla digits are translated first.
abstract final class BdPhone {
  static const String countryCode = '+880';

  /// Valid BD mobile operator prefixes (013–019).
  static final RegExp _local = RegExp(r'^01[3-9]\d{8}$');

  static String _westernDigits(String s) {
    const bn = '০১২৩৪৫৬৭৮৯';
    final buf = StringBuffer();
    for (final rune in s.runes) {
      final idx = bn.runes.toList().indexOf(rune);
      if (idx >= 0) {
        buf.write(idx);
      } else {
        buf.writeCharCode(rune);
      }
    }
    return buf.toString();
  }

  /// Returns E.164 or `null` if [raw] is not a valid BD mobile number.
  static String? normalize(String raw) {
    var digits = _westernDigits(raw).replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('880')) digits = digits.substring(3);
    if (digits.length == 10 && digits.startsWith('1')) digits = '0$digits';
    if (!_local.hasMatch(digits)) return null;
    return '$countryCode${digits.substring(1)}';
  }

  static bool isValid(String raw) => normalize(raw) != null;

  /// The 11-digit local form (`017XXXXXXXX`) for display in inputs.
  static String toLocal(String e164) =>
      e164.startsWith(countryCode) ? '0${e164.substring(4)}' : e164;
}
