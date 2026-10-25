import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/cubit/auth_cubit.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/models/notification_models.dart';
import '../domain/push_notification_service.dart';

class PushNotificationListener extends StatefulWidget {
  final GoRouter router;
  final AuthCubit authCubit;
  final NotificationRemoteDataSource notifications;
  final PushNotificationService pushNotificationService;
  final Widget child;

  const PushNotificationListener({
    super.key,
    required this.router,
    required this.authCubit,
    required this.notifications,
    required this.pushNotificationService,
    required this.child,
  });

  @override
  State<PushNotificationListener> createState() =>
      _PushNotificationListenerState();
}

class _PushNotificationListenerState extends State<PushNotificationListener> {
  StreamSubscription<PushMessage>? _messageSubscription;
  StreamSubscription<AuthState>? _authSubscription;
  PushMessage? _pendingMessage;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _messageSubscription = widget.pushNotificationService.messages.listen(
      _handleMessage,
    );
    _authSubscription = widget.authCubit.stream.listen(_handleAuthState);
    unawaited(_loadInitialMessage());
  }

  Future<void> _loadInitialMessage() async {
    try {
      final message = await widget.pushNotificationService.getInitialMessage();
      if (message != null && mounted) _handleMessage(message);
    } catch (error) {
      debugPrint('Initial push message handling failed: $error');
    }
  }

  void _handleMessage(PushMessage message) {
    if (message.source == PushMessageSource.foreground) {
      _showForegroundMessage(message);
      return;
    }

    if (widget.authCubit.state is! AuthAuthenticated) {
      _pendingMessage = message;
      return;
    }

    unawaited(_open(message));
  }

  void _handleAuthState(AuthState state) {
    if (state is AuthAuthenticated) {
      final pending = _pendingMessage;
      _pendingMessage = null;
      if (pending != null) unawaited(_open(pending));
      return;
    }

    if (state is AuthUnauthenticated) {
      _pendingMessage = null;
    }
  }

  void _showForegroundMessage(PushMessage message) {
    if (widget.authCubit.state is! AuthAuthenticated) return;

    final text = message.body ?? message.title;
    if (text == null || text.isEmpty) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(text),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _handleMessage(
            PushMessage(
              title: message.title,
              body: message.body,
              data: message.data,
              source: PushMessageSource.opened,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(PushMessage message) async {
    if (_opening) return;

    _opening = true;

    try {
      final notificationId = _asInt(message.data['notification_id']);
      AppNotificationModel? notification;

      if (notificationId != null) {
        try {
          notification = await widget.notifications.getNotification(
            notificationId,
          );
        } catch (error) {
          debugPrint('Push notification lookup failed: $error');
        }

        if (notification != null) {
          try {
            await widget.notifications.markRead(notificationId);
          } catch (error) {
            debugPrint('Push notification read acknowledgement failed: $error');
          }
        }
      }

      if (!mounted) return;

      final route = _routeFor(notification, message);

      try {
        await widget.router.push(route);
      } catch (error) {
        debugPrint('Push notification navigation failed: $error');
        if (mounted) widget.router.go('/notifications');
      }
    } finally {
      _opening = false;
    }
  }

  String _routeFor(AppNotificationModel? notification, PushMessage message) {
    final context = notification?.context ?? const <String, dynamic>{};
    final data = message.data;
    final announcementId =
        _asInt(context['announcement_id']) ??
        _asInt(data['announcement_id']) ??
        notification?.announcementId;

    if (announcementId != null) {
      return '/announcements/$announcementId';
    }

    final attendanceContext =
        _asInt(context['attendance_session_id']) ??
        _asInt(context['correction_id']) ??
        _asInt(data['attendance_session_id']) ??
        _asInt(data['correction_id']) ??
        notification?.attendanceSessionId;

    if (attendanceContext != null) return '/attendance';

    final leaveContext =
        _asInt(context['leave_request_id']) ??
        _asInt(data['leave_request_id']) ??
        notification?.leaveRequestId;

    if (leaveContext != null) return '/home';

    final type = notification?.type ?? data['type']?.toString();

    if (type != null) {
      if (type.startsWith('attendance.')) return '/attendance';
      if (type.startsWith('leave.')) return '/home';
    }

    return '/notifications';
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
