import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../core/di/injection.dart';
import '../features/announcements/data/datasources/announcement_remote_datasource.dart';
import '../features/announcements/presentation/cubit/announcement_detail_cubit.dart';
import '../features/announcements/presentation/pages/announcement_detail_page.dart';
import '../features/announcements/presentation/pages/announcements_page.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/mfa_enrollment_page.dart';
import '../features/attendance/presentation/pages/attendance_page.dart';
import '../features/employees/data/datasources/employee_remote_datasource.dart';
import '../features/employees/presentation/cubit/employee_directory_cubit.dart';
import '../features/employees/presentation/cubit/employee_profile_cubit.dart';
import '../features/employees/presentation/pages/employee_directory_page.dart';
import '../features/employees/presentation/pages/employee_profile_page.dart';
import '../features/leave/presentation/pages/leave_home_page.dart';
import '../features/notifications/presentation/pages/notification_settings_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';

class AppRouter {
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: _AuthRouterRefresh(authCubit.stream),
      redirect: (context, state) {
        final authState = authCubit.state;
        final isLoggingIn = state.matchedLocation == '/login';
        final isSplash = state.matchedLocation == '/splash';
        final isMfaEnrollment = state.matchedLocation == '/mfa-enroll';

        if (authState is AuthInitial) {
          return isSplash ? null : '/splash';
        }

        if (authState is AuthLoading) {
          return null;
        }

        if (authState is AuthMfaEnrollmentRequired ||
            authState is AuthMfaEnrollmentComplete) {
          return isMfaEnrollment ? null : '/mfa-enroll';
        }

        if (authState is AuthError) {
          return isLoggingIn ? null : '/login';
        }

        if (authState is AuthUnauthenticated) {
          return isLoggingIn ? null : '/login';
        }

        if (authState is AuthAuthenticated) {
          if (isLoggingIn || isSplash || isMfaEnrollment) {
            return '/home';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
        GoRoute(
          path: '/mfa-enroll',
          builder: (context, state) => const MfaEnrollmentPage(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const LeaveHomePage(),
        ),
        GoRoute(
          path: '/attendance',
          builder: (context, state) => const AttendancePage(),
        ),
        GoRoute(
          path: '/announcements',
          builder: (context, state) => const AnnouncementsPage(),
        ),
        GoRoute(
          path: '/announcements/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return BlocProvider(
              create: (_) => AnnouncementDetailCubit(
                getIt<AnnouncementRemoteDataSource>(),
                id,
              )..load(),
              child: const AnnouncementDetailPage(),
            );
          },
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsPage(),
        ),
        GoRoute(
          path: '/notification-settings',
          builder: (context, state) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: '/directory',
          builder: (context, state) => BlocProvider(
            create: (_) =>
                EmployeeDirectoryCubit(getIt<EmployeeRemoteDataSource>())
                  ..load(),
            child: const EmployeeDirectoryPage(),
          ),
        ),
        GoRoute(
          path: '/directory/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            return BlocProvider(
              create: (_) =>
                  EmployeeProfileCubit(getIt<EmployeeRemoteDataSource>(), id)
                    ..load(),
              child: const EmployeeProfilePage(),
            );
          },
        ),
      ],
    );
  }
}

class _AuthRouterRefresh extends ChangeNotifier {
  _AuthRouterRefresh(Stream<AuthState> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 100),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
