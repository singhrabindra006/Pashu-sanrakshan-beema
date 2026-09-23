import '../../../../core/network/result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// True when a Firebase session exists on this device.
  bool get hasFirebaseSession;

  Future<Result<UserEntity>> signIn({required String email, required String password});

  /// Firebase sign-up followed by POST /auth/sync.
  Future<Result<UserEntity>> registerFarmer({
    required String fullName,
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> syncUser({required String fullName});

  /// GET /auth/me - also used for auto-login on a cold start.
  Future<Result<UserEntity>> getCurrentUser();

  Future<Result<void>> logout();

  Future<Result<void>> sendPasswordResetEmail(String email);
}
