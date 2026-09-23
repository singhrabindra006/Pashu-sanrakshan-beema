import 'package:intl/intl.dart';

class DateFormatter {
  const DateFormatter._();

  static final DateFormat _display = DateFormat('dd MMM yyyy');
  static final DateFormat _displayWithTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _api = DateFormat('yyyy-MM-dd');
  static final NumberFormat _currency = NumberFormat.currency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 0);
  static final NumberFormat _compact = NumberFormat.compactCurrency(locale: 'en_IN', symbol: '\u20B9', decimalDigits: 1);

  /// 15 Jan 2025
  static String display(DateTime? date) => date == null ? '-' : _display.format(date.toLocal());

  /// 15 Jan 2025, 04:30 PM
  static String displayWithTime(DateTime? date) => date == null ? '-' : _displayWithTime.format(date.toLocal());

  /// yyyy-MM-dd for the API.
  static String api(DateTime date) => _api.format(date);

  /// Parses both `yyyy-MM-dd` and full ISO timestamps returned by MySQL/Node.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static String displayRaw(String? isoDate) => display(parse(isoDate));

  /// 01 Jan 2025 - 31 Dec 2025
  static String range(String? start, String? end) {
    if (start == null && end == null) return '-';
    return '${displayRaw(start)} - ${displayRaw(end)}';
  }

  static String currency(num? amount) => amount == null ? '-' : _currency.format(amount);

  static String currencyCompact(num? amount) => amount == null ? '-' : _compact.format(amount);

  /// "3 days ago" style label for activity feeds.
  static String relative(DateTime? date) {
    if (date == null) return '-';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return display(date);
  }

  /// Months -> "2 yr 6 mo", used for animal age.
  static String monthsToAge(int? months) {
    if (months == null || months <= 0) return '-';
    final years = months ~/ 12;
    final remaining = months % 12;
    if (years == 0) return '$remaining mo';
    if (remaining == 0) return '$years yr';
    return '$years yr $remaining mo';
  }
}
