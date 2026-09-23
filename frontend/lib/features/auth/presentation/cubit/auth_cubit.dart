import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_farmer_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import 'auth_state.dart';

/// Single source of truth for "who is signed in". GoRouter listens to this and
/// nothing else decides which shell the user sees.
///
/// Hydrated so a cold start can render the correct shell immediately;
/// [checkAuthStatus] then revalidates against the backend and signs the user
/// out if the session or the account is no longer valid.
class AuthCubit extends HydratedCubit<AuthState> {
  AuthCubit({
    required LoginUseCase login,
    required RegisterFarmerUseCase registerFarmer,
    required GetCurrentUserUseCase getCurrentUser,
    required LogoutUseCase logout,
    required ResetPasswordUseCase resetPassword,
  })  : _login = login,
        _registerFarmer = registerFarmer,
        _getCurrentUser = getCurrentUser,
        _logout = logout,
        _resetPassword = resetPassword,
        super(const AuthInitial());

  final LoginUseCase _login;
  final RegisterFarmerUseCase _registerFarmer;
  final GetCurrentUserUseCase _getCurrentUser;
  final LogoutUseCase _logout;
  final ResetPasswordUseCase _resetPassword;

  /// Called once by SplashScreen.
  Future<void> checkAuthStatus() async {
    if (!_getCurrentUser.hasSession) {
      emit(const AuthUnauthenticated());
      return;
    }

    // Keep the hydrated user on screen while revalidating.
    if (state is! AuthAuthenticated) emit(const AuthChecking());

    final result = await _getCurrentUser();
    result.fold(
      (user) => emit(AuthAuthenticated(user)),
      (error) async {
        // A network blip must not sign the user out; only a rejected identity does.
        if (error is NetworkException && state is AuthAuthenticated) return;
        await _logout();
        emit(AuthUnauthenticated(notice: error is AuthException ? null : error.message));
      },
    );
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthSubmitting());
    final result = await _login(email: email, password: password);
    result.fold(
      (user) => emit(AuthAuthenticated(user)),
      (error) {
        emit(AuthFailure(error.message));
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> register({required String fullName, required String email, required String password}) async {
    emit(const AuthSubmitting());
    final result = await _registerFarmer(fullName: fullName, email: email, password: password);
    result.fold(
      (user) => emit(AuthAuthenticated(user)),
      (error) {
        emit(AuthFailure(error.message));
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const AuthSubmitting());
    final result = await _resetPassword(email);
    result.fold(
      (_) => emit(const AuthUnauthenticated(notice: 'Password reset link sent. Check your inbox.')),
      (error) {
        emit(AuthFailure(error.message));
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> signOut() async {
    await _logout();
    emit(const AuthUnauthenticated());
  }

  /// Keeps the profile tab and the drawer header in sync after an edit.
  void updateProfile(UserEntity user) {
    if (state is AuthAuthenticated) emit(AuthAuthenticated(user));
  }

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    final raw = json['user'];
    if (raw is! Map<String, dynamic>) return const AuthInitial();
    try {
      return AuthAuthenticated(UserEntity.fromJson(raw));
    } catch (_) {
      return const AuthInitial();
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) =>
      state is AuthAuthenticated ? {'user': state.profile.toJson()} : {'user': null};
}
