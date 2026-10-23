import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../network/dio_client.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/leave/data/datasources/leave_remote_datasource.dart';

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
}
