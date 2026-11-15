/// Form validators. Rules mirror the backend so users get instant feedback,
/// while the API stays the source of truth.
abstract final class Validators {
  static final RegExp _phone = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)*\.[A-Za-z]{2,}$');
  static final RegExp _pan = RegExp(r'^[A-Z]{5}\d{4}[A-Z]$');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9\s]');
  static final RegExp _name = RegExp(r"^[A-Za-z][A-Za-z .'-]*$");
  static final RegExp _upi = RegExp(r'^[a-z0-9._-]{2,256}@[a-z]{2,64}$');
  static final RegExp _aadhaar = RegExp(r'^[2-9]\d{11}$');
  static final RegExp _account = RegExp(r'^\d{9,18}$');
  static final RegExp _ifsc = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');

  static bool isPhone(String value) => _phone.hasMatch(value.trim());

  static String? phone(String? value) =>
      isPhone(value ?? '') ? null : 'Enter a valid 10-digit mobile number';

  static String? required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? '$label is required' : null;

  static String? name(String? value, String label) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';
    if (!_name.hasMatch(v)) return '$label can only contain letters';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email ID is required';
    return _email.hasMatch(v) ? null : 'Enter a valid email ID';
  }

  /// Personal PAN: 5 letters, 4 digits, 1 letter, and the 4th character is "P".
  static String? pan(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (v.isEmpty) return 'PAN is required';
    if (!_pan.hasMatch(v)) return 'Enter a valid PAN, e.g. ABCPE1234F';
    if (v[3] != 'P') return 'Enter your personal PAN (the 4th character is "P")';
    return null;
  }

  /// Design rule: at least 8 characters, including at least 1 special character.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.length < 8) return 'Use at least 8 characters';
    if (!_special.hasMatch(v)) return 'Include at least 1 special character';
    return null;
  }

  static String? upi(String? value) =>
      _upi.hasMatch((value ?? '').trim().toLowerCase()) ? null : 'Enter a valid UPI ID, e.g. name@okaxis';

  static String? aadhaar(String? value) =>
      _aadhaar.hasMatch((value ?? '').replaceAll(' ', '')) ? null : 'Enter a valid 12-digit Aadhaar number';

  static String? bankAccount(String? value) =>
      _account.hasMatch((value ?? '').trim()) ? null : 'Enter a valid account number (9-18 digits)';

  static String? ifsc(String? value) =>
      _ifsc.hasMatch((value ?? '').trim().toUpperCase()) ? null : 'Enter a valid IFSC, e.g. HDFC0001234';
}
