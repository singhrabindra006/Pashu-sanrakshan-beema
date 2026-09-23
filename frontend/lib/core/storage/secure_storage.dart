import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';

/// Wrapper around FlutterSecureStorage. The Firebase SDK is the source of truth
/// for the session; this cache only exists so a cold start can pick a landing
/// route before the first network call completes.
class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  final FlutterSecureStorage _storage;

  Future<void> writeIdToken(String token) => _storage.write(key: StorageKeys.firebaseIdToken, value: token);

  Future<String?> readIdToken() => _storage.read(key: StorageKeys.firebaseIdToken);

  Future<void> writeLastKnownRole(String role) => _storage.write(key: StorageKeys.lastKnownRole, value: role);

  Future<String?> readLastKnownRole() => _storage.read(key: StorageKeys.lastKnownRole);

  Future<void> clear() async {
    await _storage.delete(key: StorageKeys.firebaseIdToken);
    await _storage.delete(key: StorageKeys.lastKnownRole);
  }
}
