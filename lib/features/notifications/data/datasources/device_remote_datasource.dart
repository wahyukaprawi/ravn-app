import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

class DeviceRemoteDataSource {
  final Dio dio;

  DeviceRemoteDataSource(this.dio);

  Future<void> registerToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    await dio.post(
      ApiConstants.devices,
      data: {
        'token': token,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
  }

  Future<void> revokeToken(int deviceId) async {
    await dio.delete('${ApiConstants.devices}/$deviceId');
  }
}
