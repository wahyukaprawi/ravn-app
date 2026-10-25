import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage;
  final Future<void> Function()? onBeforeLogout;

  AuthCubit(
    this.remoteDataSource, {
    FlutterSecureStorage? storage,
    this.onBeforeLogout,
  }) : storage = storage ?? const FlutterSecureStorage(),
       super(AuthInitial());

  Future<void> checkAuth() async {
    try {
      emit(AuthLoading());
      final token = await storage.read(key: 'auth_token');
      if (token == null) {
        emit(AuthUnauthenticated());
        return;
      }
      final user = await remoteDataSource.getMe();
      emit(AuthAuthenticated(user));
    } catch (e) {
      await storage.delete(key: 'auth_token');
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String email, String password, {String? code}) async {
    try {
      emit(AuthLoading());
      final response = await remoteDataSource.login(
        email: email,
        password: password,
        deviceName: 'Flutter App',
        code: code,
      );

      if (response.containsKey('error')) {
        final error = response['error'];
        if (error is Map && error['code'] == 'MFA_REQUIRED') {
          emit(
            const AuthError(
              'MFA enrolment is required for this account. Enrol an authenticator before signing in.',
            ),
          );
          return;
        }
        emit(
          AuthError(
            error is Map
                ? (error['message']?.toString() ?? 'Login failed')
                : 'Login failed',
          ),
        );
        return;
      }

      final token = response['token'];
      final userJson = response['user'];

      if (token == null || userJson is! Map) {
        emit(AuthError('Invalid response'));
        return;
      }

      await storage.write(key: 'auth_token', value: token.toString());
      final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));

      if (response['mfa_enrollment_required'] == true) {
        emit(AuthMfaEnrollmentRequired(user));
        return;
      }

      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(apiErrorMessage(e)));
    }
  }

  Future<void> startMfaEnrollment() async {
    final current = state;

    if (current is! AuthMfaEnrollmentRequired) {
      return;
    }

    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      final response = await remoteDataSource.enrollMfa();
      emit(
        current.copyWith(
          secret: response['secret']?.toString(),
          otpauthUrl: response['otpauth_url']?.toString(),
          isLoading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isLoading: false, error: apiErrorMessage(e)));
    }
  }

  Future<void> confirmMfaEnrollment(String code) async {
    final current = state;

    if (current is! AuthMfaEnrollmentRequired) {
      return;
    }

    emit(current.copyWith(isLoading: true, clearError: true));

    try {
      final response = await remoteDataSource.confirmMfa(code: code);
      final token = response['token'];
      final userJson = response['user'];

      if (token == null || userJson is! Map) {
        emit(
          current.copyWith(
            isLoading: false,
            error: 'The server did not return a complete session.',
          ),
        );
        return;
      }

      await storage.write(key: 'auth_token', value: token.toString());
      final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      final recoveryCodes =
          (response['recovery_codes'] as List?)
              ?.map((code) => code.toString())
              .toList() ??
          const <String>[];

      emit(AuthMfaEnrollmentComplete(user, recoveryCodes));
    } catch (e) {
      emit(current.copyWith(isLoading: false, error: apiErrorMessage(e)));
    }
  }

  void finishMfaEnrollment() {
    final current = state;

    if (current is AuthMfaEnrollmentComplete) {
      emit(AuthAuthenticated(current.user));
    }
  }

  Future<void> cancelMfaEnrollment() async {
    await logout();
  }

  Future<void> logout() async {
    try {
      await onBeforeLogout?.call();
    } catch (_) {}
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await storage.delete(key: 'auth_token');
    emit(AuthUnauthenticated());
  }
}
