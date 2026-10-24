import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/notifications/data/datasources/device_remote_datasource.dart';
import 'package:ravn/features/notifications/domain/push_notification_service.dart';
import 'package:ravn/features/notifications/domain/push_registration_service.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('registers an Android token with the device endpoint', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(token: 'android-token'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isTrue);
    expect(devices.token, 'android-token');
    expect(devices.platform, 'android');
  });

  test('registers an iOS token with the device endpoint', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(token: 'ios-token'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isTrue);
    expect(devices.platform, 'ios');
  });

  test('does not call the device endpoint without a token', () async {
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isFalse);
    expect(devices.called, isFalse);
  });

  test('swallows registration failures', () async {
    final devices = _FakeDeviceRemoteDataSource(fail: true);
    final service = PushRegistrationService(
      _FakePushNotificationService(token: 'token'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isFalse);
  });
}

class _FakePushNotificationService implements PushNotificationService {
  _FakePushNotificationService({this.token});

  final String? token;

  @override
  Future<String?> initializeAndGetToken() async => token;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class _FakeDeviceRemoteDataSource extends DeviceRemoteDataSource {
  _FakeDeviceRemoteDataSource({this.fail = false}) : super(Dio());

  final bool fail;
  bool called = false;
  String? token;
  String? platform;

  @override
  Future<void> registerToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    called = true;
    if (fail) throw StateError('network down');
    this.token = token;
    this.platform = platform;
  }
}
