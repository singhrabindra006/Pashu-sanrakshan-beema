import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'theme_state.dart';

/// Survives restarts through HydratedBloc, so the user's choice is remembered
/// without a settings API call.
class ThemeCubit extends HydratedCubit<ThemeState> {
  ThemeCubit() : super(const SystemThemeState());

  void setMode(ThemeMode mode) => emit(switch (mode) {
        ThemeMode.light => const LightThemeState(),
        ThemeMode.dark => const DarkThemeState(),
        ThemeMode.system => const SystemThemeState(),
      });

  void toggle() => emit(state.next());

  @override
  ThemeState? fromJson(Map<String, dynamic> json) => ThemeState.fromId(json['id'] as String?);

  @override
  Map<String, dynamic>? toJson(ThemeState state) => {'id': state.id};
}
