import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/attendance/data/datasources/attendance_remote_datasource.dart';
import '../../features/attendance/domain/attendance_location_service.dart';
import '../../features/attendance/domain/device_identity_service.dart';
import '../../features/attendance/domain/face_verification_service.dart';
import '../../features/announcements/data/datasources/announcement_remote_datasource.dart';
import '../../features/employees/data/datasources/employee_remote_datasource.dart';
import '../../features/leave/data/datasources/leave_remote_datasource.dart';
import '../../features/notifications/data/datasources/device_remote_datasource.dart';
import '../../features/notifications/data/datasources/notification_remote_datasource.dart';
import '../../features/notifications/data/notification_preferences_service.dart';
import '../../features/notifications/domain/push_notification_service.dart';
import '../../features/notifications/domain/push_registration_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final dioClient = DioClient();
  getIt.registerLazySingleton<Dio>(() => dioClient.dio);
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<LeaveRemoteDataSource>(
    () => LeaveRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AttendanceRemoteDataSource>(
    () => AttendanceRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<AnnouncementRemoteDataSource>(
    () => AnnouncementRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<EmployeeRemoteDataSource>(
    () => EmployeeRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<DeviceRemoteDataSource>(
    () => DeviceRemoteDataSource(getIt<Dio>()),
  );
  getIt.registerLazySingleton<NotificationPreferencesService>(
    () => NotificationPreferencesService(),
  );
  getIt.registerLazySingleton<PushNotificationService>(
    () => NoopPushNotificationService(),
  );
  getIt.registerLazySingleton<PushRegistrationService>(
    () => PushRegistrationService(
      getIt<PushNotificationService>(),
      getIt<DeviceRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<AttendanceLocationService>(
    () => GeolocatorAttendanceLocationService(),
  );
  getIt.registerLazySingleton<FaceVerificationService>(
    () => BuildConfiguredFaceVerificationService(),
  );
  getIt.registerLazySingleton<DeviceIdentityService>(
    () => SecureDeviceIdentityService(),
  );
}
