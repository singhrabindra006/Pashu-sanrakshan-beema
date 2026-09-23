import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../../../core/network/result.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/widgets/media/cached_image.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Firebase owns credentials; MySQL owns identity and role. This class is the
/// only place where those two halves are stitched together.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SecureStorage secureStorage,
    FirebaseAuth? firebaseAuth,
  })  : _remote = remote,
        _secureStorage = secureStorage,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final AuthRemoteDataSource _remote;
  final SecureStorage _secureStorage;
  final FirebaseAuth _firebaseAuth;

  @override
  bool get hasFirebaseSession => _firebaseAuth.currentUser != null;

  @override
  Future<Result<UserEntity>> signIn({required String email, required String password}) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password);
    } on FirebaseAuthException catch (error) {
      return Result.failure(AuthException(_messageFor(error), code: error.code));
    }
    return _resolveIdentity(fallbackName: _firebaseAuth.currentUser?.displayName);
  }

  @override
  Future<Result<UserEntity>> registerFarmer({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Stored on the Firebase user so a later sync retry still knows the name.
      await credential.user?.updateDisplayName(fullName.trim());
    } on FirebaseAuthException catch (error) {
      // First register created the Firebase user, then the API call failed.
      // Signing in completes POST /auth/sync instead of blocking the farmer.
      if (error.code == 'email-already-in-use') {
        return signIn(email: email, password: password);
      }
      return Result.failure(AuthException(_messageFor(error), code: error.code));
    }

    final synced = await _remote.sync(fullName: fullName.trim(), email: email.trim());
    return synced.fold(
      (user) async {
        await _cacheRole(user);
        return Result<UserEntity>.success(user);
      },
      (error) async {
        // Leave the Firebase account in place: /auth/sync is idempotent, so the
        // next sign-in completes the registration instead of losing the user.
        await _firebaseAuth.signOut();
        return Result<UserEntity>.failure(error);
      },
    );
  }

  @override
  Future<Result<UserEntity>> syncUser({required String fullName}) async {
    final result = await _remote.sync(fullName: fullName);
    if (result case Success<UserEntity>(data: final user)) await _cacheRole(user);
    return result;
  }

  @override
  Future<Result<UserEntity>> getCurrentUser() async {
    if (!hasFirebaseSession) {
      return Result.failure(const AuthException('No active session'));
    }
    return _resolveIdentity(fallbackName: _firebaseAuth.currentUser?.displayName);
  }

  /// Loads the MySQL identity, repairing a half-finished registration if the
  /// row is missing (sync failed after the Firebase account was created).
  Future<Result<UserEntity>> _resolveIdentity({String? fallbackName}) async {
    final result = await _remote.me();
    if (result case Success<UserEntity>(data: final user)) {
      await _cacheRole(user);
      return result;
    }

    final error = result.errorOrNull;
    final needsSync = error is AuthException &&
        (error.message.toLowerCase().contains('not registered') ||
            error.message.toLowerCase().contains('sync first'));
    if (needsSync) {
      final email = _firebaseAuth.currentUser?.email ?? '';
      final fromEmail = email.contains('@') ? email.split('@').first : '';
      final name = (fallbackName ?? '').trim().length >= 3
          ? fallbackName!.trim()
          : (fromEmail.length >= 3 ? fromEmail : 'Farmer');
      final synced = await _remote.sync(fullName: name, email: email.isEmpty ? null : email);
      if (synced case Success<UserEntity>(data: final user)) {
        await _cacheRole(user);
      }
      return synced;
    }
    return result;
  }

  @override
  Future<Result<void>> logout() async {
    // Best effort audit call: the local session must be cleared regardless.
    await _remote.logout();
    await _firebaseAuth.signOut();
    await _secureStorage.clear();
    AuthImageHeaders.invalidate();
    return Result.success(null);
  }

  @override
  Future<Result<void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (error) {
      return Result.failure(AuthException(_messageFor(error), code: error.code));
    }
  }

  Future<void> _cacheRole(UserEntity user) => _secureStorage.writeLastKnownRole(user.role.value);

  String _messageFor(FirebaseAuthException error) => switch (error.code) {
        'invalid-email' => 'That email address is not valid.',
        'user-disabled' => 'This account has been disabled. Contact support.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Incorrect email or password.',
        'email-already-in-use' => 'An account already exists for this email.',
        'weak-password' => 'Choose a password with at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please wait a moment and try again.',
        'network-request-failed' =>
          'Firebase could not be reached. Turn on mobile data or Wi-Fi and try again.',
        'operation-not-allowed' => 'Email/password sign-in is disabled for this project.',
        _ => error.message ?? 'Authentication failed. Please try again.',
      };
}
