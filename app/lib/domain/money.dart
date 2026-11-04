import 'package:intl/intl.dart';

/// All money is stored as integer cents. Formatting lives here only.
abstract final class Money {
  static final _whole = NumberFormat.simpleCurrency(decimalDigits: 0);
  static final _exact = NumberFormat.simpleCurrency(decimalDigits: 2);

  static String format(int cents) => cents % 100 == 0 ? _whole.format(cents / 100) : _exact.format(cents / 100);

  /// "+$212" / "-$18". Direction must never rely on color alone.
  static String signed(int cents) => '${cents < 0 ? '-' : '+'}${format(cents.abs())}';
}
