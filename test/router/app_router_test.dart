import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ravn/features/auth/data/models/user_model.dart';
import 'package:ravn/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:ravn/features/auth/presentation/pages/login_page.dart';
import 'package:ravn/features/auth/presentation/pages/mfa_enrollment_page.dart';
import 'package:ravn/router/app_router.dart';

void main() {
  testWidgets('router moves an unauthenticated session to login', (
    tester,
  ) async {
    final authCubit = _TestAuthCubit();
    final router = AppRouter.createRouter(authCubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);

    authCubit.startLoading();
    await tester.pump();
    expect(find.byType(LoginPage), findsOneWidget);

    authCubit.fail('Invalid credentials');
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);

    await authCubit.close();
  });

  testWidgets('router sends an admin without MFA to enrollment', (
    tester,
  ) async {
    final authCubit = _TestAuthCubit();
    final router = AppRouter.createRouter(authCubit);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    authCubit.enrollmentRequired();
    await tester.pumpAndSettle();

    expect(find.byType(MfaEnrollmentPage), findsOneWidget);
    expect(find.text('Set up MFA'), findsOneWidget);

    await authCubit.close();
  });
}

class _TestAuthCubit extends AuthCubit {
  _TestAuthCubit() : super(AuthRemoteDataSource(Dio()));

  @override
  Future<void> checkAuth() async {
    emit(AuthUnauthenticated());
  }

  void startLoading() => emit(AuthLoading());

  void fail(String message) => emit(AuthError(message));

  void enrollmentRequired() => emit(
    AuthMfaEnrollmentRequired(
      const UserModel(
        id: 1,
        name: 'Admin',
        email: 'admin@example.test',
        status: 'active',
        roles: ['hr_admin'],
        permissions: ['users.create'],
      ),
    ),
  );

  @override
  Future<void> startMfaEnrollment() async {}
}
