/// Form-level validation. Mirrors the express-validator rules so the user sees
/// the problem before a round trip.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
  static final RegExp _phone = RegExp(r'^[0-9+\-\s()]{7,20}$');
  static final RegExp _earTag = RegExp(r'^[A-Za-z0-9\-/]+$');

  static String? required(String? value, {String field = 'This field'}) =>
      (value == null || value.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? value) {
    final empty = required(value, field: 'Email');
    if (empty != null) return empty;
    return _email.hasMatch(value!.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? value) {
    final empty = required(value, field: 'Password');
    if (empty != null) return empty;
    if (value!.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final empty = required(value, field: 'Confirm password');
    if (empty != null) return empty;
    return value == original ? null : 'Passwords do not match';
  }

  static String? fullName(String? value) {
    final empty = required(value, field: 'Full name');
    if (empty != null) return empty;
    final trimmed = value!.trim();
    if (trimmed.length < 3) return 'Full name must be at least 3 characters';
    if (trimmed.length > 150) return 'Full name must be at most 150 characters';
    return null;
  }

  static String? phone(String? value) {
    final empty = required(value, field: 'Phone number');
    if (empty != null) return empty;
    return _phone.hasMatch(value!.trim()) ? null : 'Enter a valid phone number';
  }

  static String? earTag(String? value) {
    final empty = required(value, field: 'Ear tag');
    if (empty != null) return empty;
    final trimmed = value!.trim();
    if (trimmed.length < 3 || trimmed.length > 50) return 'Ear tag must be 3-50 characters';
    if (!_earTag.hasMatch(trimmed)) return 'Only letters, digits, - and / are allowed';
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'This field'}) =>
      (value != null && value.trim().length > max) ? '$field must be at most $max characters' : null;

  static String? minLength(String? value, int min, {String field = 'This field'}) {
    final empty = required(value, field: field);
    if (empty != null) return empty;
    return value!.trim().length < min ? '$field must be at least $min characters' : null;
  }

  static String? ageMonths(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return 'Age must be a whole number of months';
    if (parsed < 0 || parsed > 600) return 'Age must be between 0 and 600 months';
    return null;
  }

  /// Positive money value, optionally capped (e.g. a scheme's max coverage).
  static String? amount(String? value, {double? max, String field = 'Amount', double min = 0.01}) {
    final empty = required(value, field: field);
    if (empty != null) return empty;
    final parsed = double.tryParse(value!.trim().replaceAll(',', ''));
    if (parsed == null) return 'Enter a valid $field';
    if (parsed < min) return '$field must be greater than 0';
    if (max != null && parsed > max) return '$field cannot exceed ${max.toStringAsFixed(0)}';
    return null;
  }

  static String? dateRange(DateTime? start, DateTime? end) {
    if (start == null) return 'Start date is required';
    if (end == null) return 'End date is required';
    if (end.isBefore(start)) return 'End date must be on or after the start date';
    return null;
  }

  static String? rejectionReason(String? value) => minLength(value, 5, field: 'Reason');
}
