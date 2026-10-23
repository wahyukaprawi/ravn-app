import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ravn/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:ravn/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('login page validates an empty form without calling the API', (
    tester,
  ) async {
    final authCubit = AuthCubit(AuthRemoteDataSource(Dio()));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const LoginPage(),
        ),
      ),
    );

    expect(find.text('Ravn HRMS'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await authCubit.close();
  });
}
