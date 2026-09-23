import 'package:flutter/material.dart';

/// Persisted by [ThemeCubit]; [mode] is what MaterialApp consumes.
sealed class ThemeState {
  const ThemeState();

  ThemeMode get mode;
  String get id;
  String get label;

  static ThemeState fromId(String? id) => switch (id) {
        'light' => const LightThemeState(),
        'dark' => const DarkThemeState(),
        _ => const SystemThemeState(),
      };

  /// Cycles System -> Light -> Dark -> System for the single-tap toggle.
  ThemeState next() => switch (this) {
        SystemThemeState() => const LightThemeState(),
        LightThemeState() => const DarkThemeState(),
        DarkThemeState() => const SystemThemeState(),
      };
}

class SystemThemeState extends ThemeState {
  const SystemThemeState();

  @override
  ThemeMode get mode => ThemeMode.system;
  @override
  String get id => 'system';
  @override
  String get label => 'System default';
}

class LightThemeState extends ThemeState {
  const LightThemeState();

  @override
  ThemeMode get mode => ThemeMode.light;
  @override
  String get id => 'light';
  @override
  String get label => 'Light';
}

class DarkThemeState extends ThemeState {
  const DarkThemeState();

  @override
  ThemeMode get mode => ThemeMode.dark;
  @override
  String get id => 'dark';
  @override
  String get label => 'Dark';
}
