import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../../firebase_options.dart';
import '../../domain/push_notification_service.dart';

class FirebasePushNotificationService implements PushNotificationService {
  final StreamController<PushMessage> _messages =
      StreamController<PushMessage>.broadcast();
  final StreamController<String> _registrationRefreshes =
      StreamController<String>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  Future<void>? _initializing;
  bool _initialized = false;
  String? _latestRegistrationId;

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

      _subscriptions.add(
        messaging.onRegistered.listen((registrationId) {
          _latestRegistrationId = registrationId;
          _registrationRefreshes.add(registrationId);
        }),
      );
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
  Future<String?> initializeAndGetRegistrationId() async {
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

      return await _registerForMessages();
    } catch (error) {
      debugPrint('Firebase push registration failed: $error');
      return null;
    }
  }

  Future<String?> _registerForMessages() async {
    final messaging = FirebaseMessaging.instance;
    final registration = Completer<String?>();
    late final StreamSubscription<String> subscription;

    subscription = messaging.onRegistered.listen((registrationId) {
      if (registrationId.isEmpty || registration.isCompleted) return;
      registration.complete(registrationId);
    });

    try {
      await messaging.register();
      return await registration.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => _latestRegistrationId,
      );
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Future<void> unregister() async {
    if (!_initialized) return;

    try {
      await FirebaseMessaging.instance.unregister();
      _latestRegistrationId = null;
    } catch (error) {
      debugPrint('Firebase push unregistration failed: $error');
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
  Stream<String> get registrationRefreshes => _registrationRefreshes.stream;

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
    await _registrationRefreshes.close();
    _initialized = false;
    _initializing = null;
    _latestRegistrationId = null;
  }
}
