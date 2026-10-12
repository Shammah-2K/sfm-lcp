import 'package:intl/intl.dart';

/// Money is integer ngwee (1 ZMW = 100 ngwee) end to end; it is never a floating-point number.
const int maxAmountNgwee = 100000000; // K1,000,000.00

final RegExp _amountPattern = RegExp(r'^(\d*)(?:\.(\d*))?$');
final NumberFormat _kwacha = NumberFormat('#,##0', 'en_US');

/// Parses a typed amount such as "25", "25.5" or "25.50" straight into ngwee.
///
/// Returns null for anything that is not a positive amount of at most K1,000,000 with no more
/// than two decimal places.
int? parseAmountNgwee(String input) {
  final match = _amountPattern.firstMatch(input.trim());
  if (match == null) return null;
  final whole = match.group(1)!;
  final fraction = match.group(2) ?? '';
  if (whole.isEmpty && fraction.isEmpty) return null;
  if (fraction.length > 2) return null;
  final wholeDigits = whole.replaceFirst(RegExp(r'^0+'), '');
  if (wholeDigits.length > 7) return null;
  final kwacha = wholeDigits.isEmpty ? 0 : int.parse(wholeDigits);
  final ngwee = fraction.isEmpty ? 0 : int.parse(fraction.padRight(2, '0'));
  final total = kwacha * 100 + ngwee;
  if (total <= 0 || total > maxAmountNgwee) return null;
  return total;
}

/// Formats ngwee as Zambian kwacha, e.g. 2500 -> "K25.00", 125000050 -> "K1,250,000.50".
String formatNgwee(int ngwee) {
  final sign = ngwee < 0 ? '-' : '';
  final magnitude = ngwee.abs();
  final cents = (magnitude % 100).toString().padLeft(2, '0');
  return '${sign}K${_kwacha.format(magnitude ~/ 100)}.$cents';
}
