import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource(this.dio);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceName,
    String? code,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
          if (code != null) 'code': code,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> enrollMfa() async {
    final response = await dio.post(ApiConstants.mfaEnroll);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> confirmMfa({required String code}) async {
    final response = await dio.post(
      ApiConstants.mfaConfirm,
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<UserModel> getMe() async {
    final response = await dio.get(ApiConstants.me);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    await dio.post(ApiConstants.logout);
  }
}
