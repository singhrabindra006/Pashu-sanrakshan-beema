import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  UserEntity? get user => this is AuthAuthenticated ? (this as AuthAuthenticated).profile : null;
  bool get isAuthenticated => this is AuthAuthenticated;

  /// The router keeps showing the splash screen while this is true.
  bool get isResolving => this is AuthInitial || this is AuthChecking;

  @override
  List<Object?> get props => const [];
}

/// Before the first check, and after hydration fails.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Verifying the persisted session against /auth/me.
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// A login/register/reset request is in flight.
class AuthSubmitting extends AuthState {
  const AuthSubmitting();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.profile);

  final UserEntity profile;

  @override
  List<Object?> get props => [profile];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.notice});

  /// e.g. "Password reset link sent" shown on the login screen.
  final String? notice;

  @override
  List<Object?> get props => [notice];
}

/// Transient: the UI shows the message, then the cubit settles on
/// [AuthUnauthenticated].
class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
