import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../attendance/domain/device_identity_service.dart';
import '../data/datasources/device_remote_datasource.dart';
import 'push_notification_service.dart';

class PushRegistrationService {
  final PushNotificationService pushNotificationService;
  final DeviceRemoteDataSource deviceRemoteDataSource;
  final DeviceIdentityService? deviceIdentityService;

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _tokenRefreshListening = false;
  int? _registeredDeviceId;

  PushRegistrationService(
    this.pushNotificationService,
    this.deviceRemoteDataSource, {
    this.deviceIdentityService,
  });

  Future<bool> registerCurrentDevice() async {
    _startTokenRefreshRegistration();

    try {
      final token = await pushNotificationService.initializeAndGetToken();
      if (token == null || token.isEmpty) return false;

      return await _registerToken(token);
    } catch (error) {
      debugPrint('Push registration failed: $error');
      return false;
    }
  }

  void _startTokenRefreshRegistration() {
    if (_tokenRefreshListening) return;

    _tokenRefreshListening = true;
    _tokenRefreshSubscription = pushNotificationService.tokenRefreshes.listen(
      _handleTokenRefresh,
    );
  }

  void _handleTokenRefresh(String token) {
    if (token.isEmpty) return;
    unawaited(_registerTokenSafely(token));
  }

  Future<bool> _registerTokenSafely(String token) async {
    try {
      return await _registerToken(token);
    } catch (error) {
      debugPrint('Push token refresh registration failed: $error');
      return false;
    }
  }

  Future<bool> _registerToken(String token) async {
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

    final registeredId = await deviceRemoteDataSource.registerToken(
      token: token,
      platform: platform,
      deviceId: deviceId,
    );
    _registeredDeviceId = registeredId ?? _registeredDeviceId;

    return true;
  }

  Future<void> unregisterCurrentDevice() async {
    await _stopTokenRefreshRegistration();

    final deviceId = _registeredDeviceId;
    if (deviceId == null) return;

    try {
      await deviceRemoteDataSource.revokeToken(deviceId);
    } catch (error) {
      debugPrint('Push device revocation failed: $error');
    } finally {
      _registeredDeviceId = null;
    }
  }

  Future<void> dispose() async {
    await _stopTokenRefreshRegistration();
  }

  Future<void> _stopTokenRefreshRegistration() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
    _tokenRefreshListening = false;
  }
}
