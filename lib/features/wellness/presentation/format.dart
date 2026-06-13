import 'package:intl/intl.dart';

/// Small display formatters shared across the wellness screens.
class Fmt {
  static final NumberFormat _thousands = NumberFormat.decimalPattern();

  /// Minutes → "6h 18m".
  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h <= 0) return '${m}m';
    return '${h}h ${m}m';
  }

  /// 4321 → "4,321".
  static String number(int n) => _thousands.format(n);
}
