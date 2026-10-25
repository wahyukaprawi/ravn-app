import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/attendance/domain/device_identity_service.dart';
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

  test('registers the stable device identity with the token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(token: 'android-token'),
      devices,
      deviceIdentityService: _FakeDeviceIdentityService('device-123'),
    );
    addTearDown(service.dispose);

    await service.registerCurrentDevice();

    expect(devices.deviceId, 'device-123');
  });

  test('registers a refreshed token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final push = _FakePushNotificationService(token: 'initial-token');
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    await service.registerCurrentDevice();
    expect(devices.token, 'initial-token');

    push.tokenController.add('rotated-token');
    await pumpEventQueue();

    expect(devices.token, 'rotated-token');
  });

  test('revokes the registered device token', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final push = _FakePushNotificationService(token: 'android-token');
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    await service.registerCurrentDevice();
    await service.unregisterCurrentDevice();
    push.tokenController.add('late-token');
    await pumpEventQueue();

    expect(devices.revokedId, 1);
    expect(devices.token, 'android-token');
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
  final StreamController<String> tokenController =
      StreamController<String>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> initializeAndGetToken() async => token;

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get tokenRefreshes => tokenController.stream;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> dispose() async {
    await tokenController.close();
  }
}

class _FakeDeviceRemoteDataSource extends DeviceRemoteDataSource {
  _FakeDeviceRemoteDataSource({this.fail = false}) : super(Dio());

  final bool fail;
  bool called = false;
  String? token;
  String? platform;
  String? deviceId;
  int? revokedId;

  @override
  Future<int?> registerToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    called = true;
    if (fail) throw StateError('network down');
    this.token = token;
    this.platform = platform;
    this.deviceId = deviceId;
    return 1;
  }

  @override
  Future<void> revokeToken(int deviceId) async {
    revokedId = deviceId;
  }
}

class _FakeDeviceIdentityService implements DeviceIdentityService {
  _FakeDeviceIdentityService(this.deviceId);

  final String deviceId;

  @override
  Future<String> getOrCreate() async => deviceId;
}
