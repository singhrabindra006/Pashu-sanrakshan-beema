import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/result.dart';
import '../../domain/entities/user_entity.dart';

/// Thin transport layer for the three auth endpoints.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._client);

  final ApiClient _client;

  /// Creates `users` + `farmer_profiles` from the verified Firebase token.
  Future<Result<UserEntity>> sync({required String fullName, String? email}) =>
      _client.post(
        ApiEndpoints.authSync,
        body: {'full_name': fullName, 'email': ?email},
        decoder: (data) => UserEntity.fromJson(data as Map<String, dynamic>),
      );

  Future<Result<UserEntity>> me() => _client.get(
    ApiEndpoints.authMe,
    decoder: (data) => UserEntity.fromJson(data as Map<String, dynamic>),
  );

  Future<Result<void>> logout() =>
      _client.post(ApiEndpoints.authLogout, decoder: (_) {});
}
