import 'package:intl/intl.dart';

/// Money is integer ngwee (K1 = 100 ngwee) everywhere; it is never a double.

final NumberFormat _grouped = NumberFormat('#,##0', 'en_US');

/// `2500` → `K25.00`; `100000050` → `K1,000,000.50`. Negative values keep a
/// true minus sign: `−K25.00`.
String formatKwacha(int ngwee) {
  final sign = ngwee < 0 ? '−' : '';
  final abs = ngwee.abs();
  final cents = (abs % 100).toString().padLeft(2, '0');
  return '${sign}K${_grouped.format(abs ~/ 100)}.$cents';
}

/// A signed amount for lists and totals: `+K50.00` or `−K25.00`.
String formatSignedKwacha(int ngwee, {required bool moneyIn}) =>
    '${moneyIn ? '+' : '−'}${formatKwacha(ngwee.abs())}';

final RegExp _typedAmount = RegExp(r'^(\d*)(?:\.(\d{0,2}))?$');

/// Converts keypad text such as `25`, `25.5` or `25.50` to ngwee without
/// passing through a double. Returns null for text that is not a well-formed
/// amount above zero. Range limits are the ledger's decision, not the keypad's.
int? parseTypedNgwee(String text) {
  final match = _typedAmount.firstMatch(text);
  if (match == null) return null;
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) return null;
  final kwacha = whole.isEmpty ? 0 : int.parse(whole);
  final ngwee = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  final total = kwacha * 100 + ngwee;
  return total > 0 ? total : null;
}

/// The reverse of [parseTypedNgwee], for showing a worked-out amount on the
/// keypad display: `20000` → `200`, `2550` → `25.50`.
String typedFromNgwee(int ngwee) {
  final cents = ngwee % 100;
  return cents == 0
      ? '${ngwee ~/ 100}'
      : '${ngwee ~/ 100}.${cents.toString().padLeft(2, '0')}';
}

/// What the amount display shows while typing: `K` + the typed text, or `K0`.
String typedAmountLabel(String text) => 'K${text.isEmpty ? '0' : text}';
