import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Display helpers (Indian number grouping: 1,00,000).
abstract final class Fmt {
  static final NumberFormat _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final NumberFormat _grouped = NumberFormat.decimalPattern('en_IN');
  static final DateFormat _date = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dob = DateFormat('dd - MM - yyyy');

  /// 30000 -> ₹30,000
  static String inr(num amount) => _inr.format(amount);

  /// 30000 -> 30,000
  static String grouped(num amount) => _grouped.format(amount);

  /// 1.0 -> "1%", 0.5 -> "0.5%"
  static String percent(num value) => '${value % 1 == 0 ? value.toInt() : value}%';

  static String date(DateTime date) => _date.format(date.toLocal());

  static String dateTime(DateTime date) => _dateTime.format(date.toLocal());

  /// The DD - MM - YYYY style used by the date field in the design.
  static String dob(DateTime date) => _dob.format(date);

  /// 9876543210 -> +91 98765 43210
  static String phone(String phone) =>
      phone.length == 10 ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : '+91 $phone';

  /// 65 -> 01:05
  static String countdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// "Asha Verma" -> "AV"
  static String initials(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CS';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Upper-cases input as the user types (PAN, IFSC).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
