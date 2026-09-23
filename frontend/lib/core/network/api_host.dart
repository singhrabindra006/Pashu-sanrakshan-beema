import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/prefs_storage.dart';

/// Picks a reachable API origin so USB, emulator and Wi-Fi all work
/// without editing a hardcoded LAN IP after you change networks.
class ApiHost {
  ApiHost._();

  /// Laptop Wi-Fi IPv4. After you change networks, put the new IPv4 here
  /// (same port 4000) or run with `--dart-define=API_BASE_URL=http://NEW_IP:4000/api/v1`.
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.66:4000/api/v1',
  );

  static String _baseUrl = configuredBaseUrl;

  static String get baseUrl => _baseUrl;

  static List<String> candidates(PrefsStorage prefs) {
    final extras = const String.fromEnvironment('API_HOSTS')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final remembered = prefs.lastApiBaseUrl;
    return {
      configuredBaseUrl,
      if (remembered != null && remembered.isNotEmpty) remembered,
      'http://127.0.0.1:4000/api/v1',
      'http://10.0.2.2:4000/api/v1',
      ...extras,
    }.toList();
  }

  static Future<String> resolve(PrefsStorage prefs) async {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    for (final candidate in candidates(prefs)) {
      final health = _healthUrl(candidate);
      try {
        final response = await dio.get<dynamic>(health);
        if (response.statusCode != null && response.statusCode! < 400) {
          _baseUrl = candidate;
          await prefs.setLastApiBaseUrl(candidate);
          debugPrint('[api] reachable at $_baseUrl');
          return candidate;
        }
      } catch (_) {
        // Try the next host — USB, emulator and Wi-Fi are different.
      }
    }

    _baseUrl = configuredBaseUrl;
    return _baseUrl;
  }

  static String _healthUrl(String apiBase) {
    final uri = Uri.parse(apiBase);
    return uri.replace(path: '/health', query: '').toString();
  }
}
