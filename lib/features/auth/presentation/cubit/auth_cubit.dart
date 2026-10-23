import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_error_message.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/user_model.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRemoteDataSource remoteDataSource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthCubit(this.remoteDataSource) : super(AuthInitial());

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
      if (token != null) {
        await storage.write(key: 'auth_token', value: token.toString());
        final user = UserModel.fromJson(
          response['user'] as Map<String, dynamic>,
        );
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('Invalid response'));
      }
    } catch (e) {
      emit(AuthError(apiErrorMessage(e)));
    }
  }

  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await storage.delete(key: 'auth_token');
    emit(AuthUnauthenticated());
  }
}
