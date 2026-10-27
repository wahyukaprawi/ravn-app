import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';

class DeviceRemoteDataSource {
  final Dio dio;

  DeviceRemoteDataSource(this.dio);

  Future<int?> registerDevice({
    required String registrationId,
    required String platform,
    String? deviceId,
  }) async {
    final response = await dio.post(
      ApiConstants.devices,
      data: {
        'token': registrationId,
        'platform': platform,
        if (deviceId != null) 'device_id': deviceId,
      },
    );

    final body = response.data;
    if (body is! Map) return null;

    final data = body['data'];
    if (data is! Map) return null;

    return _asInt(data['id']);
  }

  Future<void> revokeDevice(int deviceId) async {
    await dio.delete('${ApiConstants.devices}/$deviceId');
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
