// Fails CI when the Bangla ARB is missing keys present in the English
// template, or has stray keys. Missing BN strings silently fall back to
// English at runtime — exactly the kind of bug that never shows up on a
// developer's en-US emulator.
//
// Usage: dart run tool/check_l10n.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final en = _load('lib/l10n/app_en.arb');
  final bn = _load('lib/l10n/app_bn.arb');

  final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
  final bnKeys = bn.keys.where((k) => !k.startsWith('@')).toSet();

  final missing = enKeys.difference(bnKeys).toList()..sort();
  final extra = bnKeys.difference(enKeys).toList()..sort();
  final untranslated =
      enKeys
          .where(
            (k) =>
                bnKeys.contains(k) && bn[k] == en[k] && _looksLikeProse(en[k]),
          )
          .toList()
        ..sort();

  var failed = false;
  if (missing.isNotEmpty) {
    failed = true;
    stderr.writeln('app_bn.arb is missing ${missing.length} key(s):');
    for (final k in missing) {
      stderr.writeln('  - $k');
    }
  }
  if (extra.isNotEmpty) {
    failed = true;
    stderr.writeln('app_bn.arb has ${extra.length} key(s) not in app_en.arb:');
    for (final k in extra) {
      stderr.writeln('  - $k');
    }
  }
  if (untranslated.isNotEmpty) {
    // Warning only: brand names / "OTP" / "SOS" are legitimately identical.
    stdout.writeln(
      'note: ${untranslated.length} BN value(s) identical to EN '
      '(check these are intentional):',
    );
    for (final k in untranslated) {
      stdout.writeln('  - $k');
    }
  }

  if (failed) exit(1);
  stdout.writeln('l10n ok: ${enKeys.length} keys, BN complete.');
}

Map<String, Object?> _load(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;

bool _looksLikeProse(Object? v) =>
    v is String && v.trim().split(RegExp(r'\s+')).length >= 3;
