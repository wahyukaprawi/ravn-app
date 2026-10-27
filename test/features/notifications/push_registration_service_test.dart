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

  test('registers an Android FID with the device endpoint', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(registrationId: 'android-fid'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isTrue);
    expect(devices.registrationId, 'android-fid');
    expect(devices.platform, 'android');
  });

  test('registers an iOS FID with the device endpoint', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(registrationId: 'ios-fid'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isTrue);
    expect(devices.platform, 'ios');
  });

  test('registers the stable device identity with the FID', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final service = PushRegistrationService(
      _FakePushNotificationService(registrationId: 'android-fid'),
      devices,
      deviceIdentityService: _FakeDeviceIdentityService('device-123'),
    );
    addTearDown(service.dispose);

    await service.registerCurrentDevice();

    expect(devices.deviceId, 'device-123');
  });

  test('registers a refreshed FID', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource();
    final push = _FakePushNotificationService(registrationId: 'initial-fid');
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    await service.registerCurrentDevice();
    expect(devices.registrationId, 'initial-fid');

    push.registrationController.add('rotated-fid');
    await pumpEventQueue();

    expect(devices.registrationId, 'rotated-fid');
  });

  test('revokes the device and provider registration on logout', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final events = <String>[];
    final devices = _FakeDeviceRemoteDataSource(events: events);
    final push = _FakePushNotificationService(
      registrationId: 'android-fid',
      events: events,
    );
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    await service.registerCurrentDevice();
    await service.unregisterCurrentDevice();
    push.registrationController.add('late-fid');
    await pumpEventQueue();

    expect(devices.revokedId, 1);
    expect(devices.registrationId, 'android-fid');
    expect(push.unregistered, isTrue);
    expect(events, ['register', 'revoke', 'unregister']);
  });

  test('unregisters the provider when backend revocation fails', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final devices = _FakeDeviceRemoteDataSource(revokeFail: true);
    final push = _FakePushNotificationService(registrationId: 'android-fid');
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    await service.registerCurrentDevice();
    await service.unregisterCurrentDevice();

    expect(push.unregistered, isTrue);
  });

  test('does not call the device endpoint without a FID', () async {
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
      _FakePushNotificationService(registrationId: 'android-fid'),
      devices,
    );

    final registered = await service.registerCurrentDevice();

    expect(registered, isFalse);
  });

  test('ignores registration that completes after logout', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final registration = Completer<String?>();
    final devices = _FakeDeviceRemoteDataSource();
    final push = _FakePushNotificationService(
      registrationFuture: registration.future,
    );
    final service = PushRegistrationService(push, devices);
    addTearDown(service.dispose);

    final pending = service.registerCurrentDevice();
    await service.unregisterCurrentDevice();
    registration.complete('late-fid');

    expect(await pending, isFalse);
    expect(devices.called, isFalse);
    expect(push.unregistered, isTrue);
  });
}

class _FakePushNotificationService implements PushNotificationService {
  _FakePushNotificationService({
    this.registrationId,
    this.registrationFuture,
    this.events,
  });

  final String? registrationId;
  final Future<String?>? registrationFuture;
  final List<String>? events;
  final StreamController<String> registrationController =
      StreamController<String>.broadcast();
  bool unregistered = false;

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> initializeAndGetRegistrationId() async {
    final future = registrationFuture;
    return future == null ? registrationId : await future;
  }

  @override
  Future<PushMessage?> getInitialMessage() async => null;

  @override
  Stream<String> get registrationRefreshes => registrationController.stream;

  @override
  Stream<PushMessage> get messages => const Stream.empty();

  @override
  Future<void> unregister() async {
    unregistered = true;
    events?.add('unregister');
  }

  @override
  Future<void> dispose() async {
    await registrationController.close();
  }
}

class _FakeDeviceRemoteDataSource extends DeviceRemoteDataSource {
  _FakeDeviceRemoteDataSource({
    this.fail = false,
    this.revokeFail = false,
    this.events,
  }) : super(Dio());

  final bool fail;
  final bool revokeFail;
  final List<String>? events;
  bool called = false;
  String? registrationId;
  String? platform;
  String? deviceId;
  int? revokedId;

  @override
  Future<int?> registerDevice({
    required String registrationId,
    required String platform,
    String? deviceId,
  }) async {
    called = true;
    events?.add('register');
    if (fail) throw StateError('network down');
    this.registrationId = registrationId;
    this.platform = platform;
    this.deviceId = deviceId;
    return 1;
  }

  @override
  Future<void> revokeDevice(int deviceId) async {
    events?.add('revoke');
    if (revokeFail) throw StateError('revoke failed');
    revokedId = deviceId;
  }
}

class _FakeDeviceIdentityService implements DeviceIdentityService {
  _FakeDeviceIdentityService(this.deviceId);

  final String deviceId;

  @override
  Future<String> getOrCreate() async => deviceId;
}
