import 'package:flutter/material.dart';

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  MediaQueryData get media => MediaQuery.of(this);
  Size get screenSize => MediaQuery.sizeOf(this);
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Tablet/landscape breakpoint used by ResponsiveLayout.
  bool get isWide => MediaQuery.sizeOf(this).width >= 720;

  void hideKeyboard() => FocusScope.of(this).unfocus();
}

extension StringX on String {
  bool get isBlank => trim().isEmpty;

  String get capitalised => isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  /// COW -> Cow, NATURAL_DISASTER -> Natural disaster
  String get humanised => isEmpty ? this : split('_').map((part) => part.toLowerCase()).join(' ').capitalised;

  /// "Ram Bahadur Thapa" -> "RT"
  String get initials {
    final parts = trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

extension NullableStringX on String? {
  String orDash() => (this == null || this!.trim().isEmpty) ? '-' : this!;
  bool get isNullOrBlank => this == null || this!.trim().isEmpty;
}

extension NumX on num {
  String get asCompact => this >= 100000
      ? '${(this / 100000).toStringAsFixed(1)}L'
      : this >= 1000
          ? '${(this / 1000).toStringAsFixed(1)}K'
          : toString();
}

extension DateTimeX on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
  bool isSameDay(DateTime other) => dateOnly == other.dateOnly;
}

extension ListX<T> on List<T> {
  /// Inserts [separator] between items - handy for Column children.
  List<T> separatedBy(T separator) {
    if (length < 2) return this;
    final result = <T>[];
    for (var i = 0; i < length; i++) {
      result.add(this[i]);
      if (i != length - 1) result.add(separator);
    }
    return result;
  }
}
