import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_options.dart';
import '../../domain/push_notification_service.dart';

class FirebasePushNotificationService implements PushNotificationService {
  final StreamController<PushMessage> _messages =
      StreamController<PushMessage>.broadcast();
  final StreamController<String> _tokenRefreshes =
      StreamController<String>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<void>? _initializing;
  bool _initialized = false;

  bool get _isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  Future<void> initialize() {
    if (!_isSupported || _initialized) return Future<void>.value();
    return _initializing ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final messaging = FirebaseMessaging.instance;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      _subscriptions.add(messaging.onTokenRefresh.listen(_tokenRefreshes.add));
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen(
          (message) => _messages.add(
            _toPushMessage(message, PushMessageSource.foreground),
          ),
        ),
      );
      _subscriptions.add(
        FirebaseMessaging.onMessageOpenedApp.listen(
          (message) =>
              _messages.add(_toPushMessage(message, PushMessageSource.opened)),
        ),
      );

      _initialized = true;
    } catch (error) {
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      debugPrint('Firebase push initialization failed: $error');
      _initializing = null;
    }
  }

  @override
  Future<String?> initializeAndGetToken() async {
    await initialize();

    if (!_initialized) return null;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Firebase push token request failed: $error');
      return null;
    }
  }

  @override
  Future<PushMessage?> getInitialMessage() async {
    if (!_initialized) return null;

    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      return message == null
          ? null
          : _toPushMessage(message, PushMessageSource.opened);
    } catch (error) {
      debugPrint('Firebase initial push message failed: $error');
      return null;
    }
  }

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshes.stream;

  @override
  Stream<PushMessage> get messages => _messages.stream;

  PushMessage _toPushMessage(RemoteMessage message, PushMessageSource source) {
    return PushMessage(
      title: message.notification?.title,
      body: message.notification?.body,
      data: Map<String, dynamic>.from(message.data),
      source: source,
    );
  }

  @override
  Future<void> dispose() async {
    final initializing = _initializing;
    if (initializing != null) await initializing;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _messages.close();
    await _tokenRefreshes.close();
    _initialized = false;
    _initializing = null;
  }
}
