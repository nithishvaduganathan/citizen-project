part of 'auth_bloc.dart';

/// Authentication events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check if user is authenticated
class AuthCheckRequested extends AuthEvent {}

/// Login with email and password
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Register new user
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String username;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
    required this.username,
  });

  @override
  List<Object?> get props => [email, password, fullName, username];
}

/// Sign in with Google
class AuthGoogleSignInRequested extends AuthEvent {}

/// Admin login
class AuthAdminLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthAdminLoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Logout
class AuthLogoutRequested extends AuthEvent {}

/// User updated
class AuthUserUpdated extends AuthEvent {
  final User user;

  const AuthUserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}
