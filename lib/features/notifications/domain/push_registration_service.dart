import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../attendance/domain/device_identity_service.dart';
import '../data/datasources/device_remote_datasource.dart';
import 'push_notification_service.dart';

class PushRegistrationService {
  final PushNotificationService pushNotificationService;
  final DeviceRemoteDataSource deviceRemoteDataSource;
  final DeviceIdentityService? deviceIdentityService;

  StreamSubscription<String>? _registrationRefreshSubscription;
  bool _registrationRefreshListening = false;
  bool _acceptRegistrations = false;
  int _registrationGeneration = 0;
  int? _registeredDeviceId;

  PushRegistrationService(
    this.pushNotificationService,
    this.deviceRemoteDataSource, {
    this.deviceIdentityService,
  });

  Future<bool> registerCurrentDevice() async {
    final generation = ++_registrationGeneration;

    try {
      final registrationId = await pushNotificationService
          .initializeAndGetRegistrationId();

      if (!_isCurrentGeneration(generation)) return false;

      if (registrationId == null || registrationId.isEmpty) {
        return false;
      }

      _acceptRegistrations = true;
      _startRegistrationRefreshRegistration();

      return await _registerRegistrationId(registrationId, generation);
    } catch (error) {
      debugPrint('Push registration failed: $error');
      return false;
    }
  }

  void _startRegistrationRefreshRegistration() {
    if (_registrationRefreshListening) return;

    _registrationRefreshListening = true;
    _registrationRefreshSubscription = pushNotificationService
        .registrationRefreshes
        .listen(_handleRegistrationRefresh);
  }

  void _handleRegistrationRefresh(String registrationId) {
    if (!_acceptRegistrations || registrationId.isEmpty) return;
    unawaited(
      _registerRegistrationIdSafely(registrationId, _registrationGeneration),
    );
  }

  Future<bool> _registerRegistrationIdSafely(
    String registrationId,
    int generation,
  ) async {
    try {
      return await _registerRegistrationId(registrationId, generation);
    } catch (error) {
      debugPrint('Push registration refresh failed: $error');
      return false;
    }
  }

  Future<bool> _registerRegistrationId(
    String registrationId,
    int generation,
  ) async {
    if (!_isActive(generation)) return false;

    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => null,
    };
    if (platform == null) return false;

    String? deviceId;
    try {
      deviceId = await deviceIdentityService?.getOrCreate();
    } catch (error) {
      debugPrint('Push device identity failed: $error');
    }

    if (!_isActive(generation)) return false;

    final registeredId = await deviceRemoteDataSource.registerDevice(
      registrationId: registrationId,
      platform: platform,
      deviceId: deviceId,
    );

    if (!_isActive(generation)) {
      await _revokeQuietly(registeredId);
      return false;
    }

    _registeredDeviceId = registeredId ?? _registeredDeviceId;

    return true;
  }

  Future<void> unregisterCurrentDevice() async {
    _registrationGeneration++;
    _acceptRegistrations = false;
    await _stopRegistrationRefreshRegistration();

    final deviceId = _registeredDeviceId;
    _registeredDeviceId = null;

    try {
      if (deviceId != null) {
        await deviceRemoteDataSource.revokeDevice(deviceId);
      }
    } catch (error) {
      debugPrint('Push device revocation failed: $error');
    }

    try {
      await pushNotificationService.unregister();
    } catch (error) {
      debugPrint('Push provider unregistration failed: $error');
    }
  }

  Future<void> dispose() async {
    _registrationGeneration++;
    _acceptRegistrations = false;
    await _stopRegistrationRefreshRegistration();
  }

  Future<void> _stopRegistrationRefreshRegistration() async {
    await _registrationRefreshSubscription?.cancel();
    _registrationRefreshSubscription = null;
    _registrationRefreshListening = false;
  }

  Future<void> _revokeQuietly(int? deviceId) async {
    if (deviceId == null) return;

    try {
      await deviceRemoteDataSource.revokeDevice(deviceId);
    } catch (error) {
      debugPrint('Push device cleanup failed: $error');
    }
  }

  bool _isCurrentGeneration(int generation) =>
      generation == _registrationGeneration;

  bool _isActive(int generation) =>
      _acceptRegistrations && _isCurrentGeneration(generation);
}
