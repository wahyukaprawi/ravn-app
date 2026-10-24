import 'package:flutter/foundation.dart';
import '../data/datasources/device_remote_datasource.dart';
import 'push_notification_service.dart';

class PushRegistrationService {
  final PushNotificationService pushNotificationService;
  final DeviceRemoteDataSource deviceRemoteDataSource;

  PushRegistrationService(
    this.pushNotificationService,
    this.deviceRemoteDataSource,
  );

  Future<bool> registerCurrentDevice() async {
    if (kIsWeb) return false;

    try {
      final token = await pushNotificationService.initializeAndGetToken();
      if (token == null || token.isEmpty) return false;

      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'ios',
        TargetPlatform.android => 'android',
        _ => null,
      };
      if (platform == null) return false;

      await deviceRemoteDataSource.registerToken(
        token: token,
        platform: platform,
      );

      return true;
    } catch (error) {
      debugPrint('Push registration failed: $error');
      return false;
    }
  }
}
