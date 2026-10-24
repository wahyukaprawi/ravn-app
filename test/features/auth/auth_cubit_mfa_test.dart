import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ravn/features/auth/presentation/cubit/auth_cubit.dart';

void main() {
  test(
    'an unenrolled admin completes MFA enrollment and receives a session',
    () async {
      final storage = _MemoryStorage();
      final remote = _FakeAuthRemoteDataSource();
      final cubit = AuthCubit(remote, storage: storage);

      await cubit.login('admin@example.test', 'correct-password', code: null);

      expect(cubit.state, isA<AuthMfaEnrollmentRequired>());
      expect(remote.loginCalls, 1);
      expect(storage.values['auth_token'], 'enrollment-token');

      await cubit.startMfaEnrollment();

      final required = cubit.state as AuthMfaEnrollmentRequired;
      expect(required.secret, 'SYNTHETIC-SECRET');
      expect(required.otpauthUrl, startsWith('otpauth://totp/'));
      expect(remote.enrollCalls, 1);

      await cubit.confirmMfaEnrollment('123456');

      final complete = cubit.state as AuthMfaEnrollmentComplete;
      expect(complete.recoveryCodes, ['CODE-ONE', 'CODE-TWO']);
      expect(remote.confirmCalls, 1);
      expect(storage.values['auth_token'], 'full-session-token');

      cubit.finishMfaEnrollment();

      expect(cubit.state, isA<AuthAuthenticated>());
      expect(
        (cubit.state as AuthAuthenticated).user.email,
        'admin@example.test',
      );

      await cubit.close();
    },
  );
}

class _FakeAuthRemoteDataSource extends AuthRemoteDataSource {
  _FakeAuthRemoteDataSource() : super(Dio());

  int loginCalls = 0;
  int enrollCalls = 0;
  int confirmCalls = 0;

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
    String? code,
  }) async {
    loginCalls++;

    return {
      'mfa_enrollment_required': true,
      'token': 'enrollment-token',
      'expires_at': '2026-10-23T12:10:00+00:00',
      'user': _user,
    };
  }

  @override
  Future<Map<String, dynamic>> enrollMfa() async {
    enrollCalls++;

    return {
      'secret': 'SYNTHETIC-SECRET',
      'otpauth_url':
          'otpauth://totp/Ravn:admin@example.test?secret=SYNTHETIC-SECRET',
    };
  }

  @override
  Future<Map<String, dynamic>> confirmMfa({required String code}) async {
    confirmCalls++;

    return {
      'token': 'full-session-token',
      'user': _user,
      'recovery_codes': ['CODE-ONE', 'CODE-TWO'],
    };
  }

  @override
  Future<void> logout() async {}
}

class _MemoryStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
      return;
    }

    values[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

const _user = {
  'id': 7,
  'name': 'Synthetic Admin',
  'email': 'admin@example.test',
  'status': 'active',
  'roles': ['hr_admin'],
  'permissions': ['users.create'],
};
