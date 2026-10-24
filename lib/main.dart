import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/leave/presentation/cubit/leave_cubit.dart';
import 'features/leave/data/datasources/leave_remote_datasource.dart';
import 'features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'features/attendance/domain/attendance_location_service.dart';
import 'features/attendance/domain/device_identity_service.dart';
import 'features/attendance/domain/face_verification_service.dart';
import 'features/attendance/presentation/cubit/attendance_cubit.dart';
import 'features/announcements/data/datasources/announcement_remote_datasource.dart';
import 'features/announcements/presentation/cubit/announcement_cubit.dart';
import 'features/notifications/data/datasources/notification_remote_datasource.dart';
import 'features/notifications/domain/push_registration_service.dart';
import 'features/notifications/presentation/cubit/notification_cubit.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authDataSource = getIt<AuthRemoteDataSource>();
    final leaveDataSource = getIt<LeaveRemoteDataSource>();
    final attendanceDataSource = getIt<AttendanceRemoteDataSource>();
    final announcementDataSource = getIt<AnnouncementRemoteDataSource>();
    final notificationDataSource = getIt<NotificationRemoteDataSource>();

    final authCubit = AuthCubit(authDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<LeaveCubit>(
          create: (context) => LeaveCubit(leaveDataSource),
        ),
        BlocProvider<AttendanceCubit>(
          create: (context) => AttendanceCubit(
            attendanceDataSource,
            getIt<AttendanceLocationService>(),
            getIt<FaceVerificationService>(),
            getIt<DeviceIdentityService>(),
          ),
        ),
        BlocProvider<AnnouncementCubit>(
          create: (context) => AnnouncementCubit(announcementDataSource),
        ),
        BlocProvider<NotificationCubit>(
          create: (context) => NotificationCubit(notificationDataSource),
        ),
      ],
      child: Builder(
        builder: (context) {
          final router = AppRouter.createRouter(context.read<AuthCubit>());
          return BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthAuthenticated) {
                unawaited(
                  getIt<PushRegistrationService>().registerCurrentDevice(),
                );
              }

              if (state is AuthUnauthenticated) {
                context.read<AnnouncementCubit>().clear();
                context.read<NotificationCubit>().clear();
              }
            },
            child: MaterialApp.router(
              title: 'Ravn HRMS',
              theme: AppTheme.lightTheme,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
