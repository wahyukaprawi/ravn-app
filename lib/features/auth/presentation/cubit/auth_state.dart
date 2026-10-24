part of 'auth_cubit.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthMfaEnrollmentRequired extends AuthState {
  final UserModel user;
  final String? secret;
  final String? otpauthUrl;
  final bool isLoading;
  final String? error;

  const AuthMfaEnrollmentRequired(
    this.user, {
    this.secret,
    this.otpauthUrl,
    this.isLoading = false,
    this.error,
  });

  AuthMfaEnrollmentRequired copyWith({
    String? secret,
    String? otpauthUrl,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AuthMfaEnrollmentRequired(
      user,
      secret: secret ?? this.secret,
      otpauthUrl: otpauthUrl ?? this.otpauthUrl,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [user, secret, otpauthUrl, isLoading, error];
}

class AuthMfaEnrollmentComplete extends AuthState {
  final UserModel user;
  final List<String> recoveryCodes;

  const AuthMfaEnrollmentComplete(this.user, this.recoveryCodes);

  @override
  List<Object?> get props => [user, recoveryCodes];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
