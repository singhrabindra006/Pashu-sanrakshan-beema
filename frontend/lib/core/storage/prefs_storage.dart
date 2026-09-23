import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

/// Non-sensitive flags. [init] is awaited once in main() so reads stay sync.
class PrefsStorage {
  PrefsStorage(this._prefs);

  final SharedPreferences _prefs;

  static Future<PrefsStorage> init() async => PrefsStorage(await SharedPreferences.getInstance());

  bool get onboardingSeen => _prefs.getBool(StorageKeys.onboardingSeen) ?? false;

  Future<void> setOnboardingSeen(bool value) => _prefs.setBool(StorageKeys.onboardingSeen, value);

  String? get lastApiBaseUrl => _prefs.getString(StorageKeys.lastApiBaseUrl);

  Future<void> setLastApiBaseUrl(String url) => _prefs.setString(StorageKeys.lastApiBaseUrl, url);
}
