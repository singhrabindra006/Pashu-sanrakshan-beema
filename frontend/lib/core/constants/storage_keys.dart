class StorageKeys {
  const StorageKeys._();

  // FlutterSecureStorage
  static const String firebaseIdToken = 'firebase_id_token';
  static const String lastKnownRole = 'last_known_role';

  // SharedPreferences
  static const String onboardingSeen = 'onboarding_seen';
  static const String lastApiBaseUrl = 'last_api_base_url';

  // HydratedBloc storage ids
  static const String themeCubit = 'ThemeCubit';
  static const String authCubit = 'AuthCubit';
}
