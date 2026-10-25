import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ravn/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:ravn/features/auth/data/models/user_model.dart';
import 'package:ravn/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:ravn/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:ravn/features/notifications/data/models/notification_models.dart';
import 'package:ravn/features/notifications/domain/push_notification_service.dart';
import 'package:ravn/features/notifications/presentation/push_notification_listener.dart';

void main() {
  testWidgets('opens an announcement from an opened push message', (
    tester,
  ) async {
    final auth = _TestAuthCubit()..authenticate();
    final notifications = _FakeNotificationRemoteDataSource();
    final push = _FakePushNotificationService();
    final router = _testRouter();
    addTearDown(auth.close);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        auth: auth,
        notifications: notifications,
        push: push,
      ),
    );
    await tester.pumpAndSettle();

    push.add(
      const PushMessage(
        data: {'notification_id': '7'},
        source: PushMessageSource.opened,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Announcement 42'), findsOneWidget);
    expect(notifications.markedReadId, 7);
  });

  testWidgets('waits for authentication before opening a push message', (
    tester,
  ) async {
    final auth = _TestAuthCubit();
    final notifications = _FakeNotificationRemoteDataSource();
    final push = _FakePushNotificationService();
    final router = _testRouter();
    addTearDown(auth.close);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        auth: auth,
        notifications: notifications,
        push: push,
      ),
    );
    await tester.pumpAndSettle();

    push.add(
      const PushMessage(
        data: {'notification_id': '7'},
        source: PushMessageSource.opened,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Announcement 42'), findsNothing);

    auth.authenticate();
    await tester.pumpAndSettle();

    expect(find.text('Announcement 42'), findsOneWidget);
  });

  testWidgets('falls back to the notification list when lookup fails', (
    tester,
  ) async {
    final auth = _TestAuthCubit()..authenticate();
    final notifications = _FakeNotificationRemoteDataSource(fail: true);
    final push = _FakePushNotificationService();
    final router = _testRouter();
    addTearDown(auth.close);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        auth: auth,
        notifications: notifications,
        push: push,
      ),
    );
    await tester.pumpAndSettle();

    push.add(
      const PushMessage(
        data: {'notification_id': '7'},
        source: PushMessageSource.opened,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('opens the initial message after startup', (tester) async {
    final auth = _TestAuthCubit()..authenticate();
    final notifications = _FakeNotificationRemoteDataSource();
    final push = _FakePushNotificationService(
      initialMessage: const PushMessage(
        data: {'notification_id': '7'},
        source: PushMessageSource.opened,
      ),
    );
    final router = _testRouter();
    addTearDown(auth.close);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        auth: auth,
        notifications: notifications,
        push: push,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Announcement 42'), findsOneWidget);
  });

  testWidgets('shows a foreground push message in a snackbar', (tester) async {
    final auth = _TestAuthCubit()..authenticate();
    final notifications = _FakeNotificationRemoteDataSource();
    final push = _FakePushNotificationService();
    final router = _testRouter();
    addTearDown(auth.close);
    addTearDown(push.dispose);

    await tester.pumpWidget(
      _app(
        router: router,
        auth: auth,
        notifications: notifications,
        push: push,
      ),
    );
    await tester.pumpAndSettle();

    push.add(
      const PushMessage(
        title: 'New notification',
        body: 'A leave request needs your review.',
        source: PushMessageSource.foreground,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A leave request needs your review.'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
  });
}

Widget _app({
  required GoRouter router,
  required AuthCubit auth,
  required NotificationRemoteDataSource notifications,
  required PushNotificationService push,
}) {
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => PushNotificationListener(
      router: router,
      authCubit: auth,
      notifications: notifications,
      pushNotificationService: push,
      child: child ?? const SizedBox.shrink(),
    ),
  );
}

GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => const Scaffold(body: Text('Home')),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const Scaffold(body: Text('Notifications')),
      ),
      GoRoute(
        path: '/announcements/:id',
        builder: (context, state) =>
            Scaffold(body: Text('Announcement ${state.pathParameters['id']}')),
      ),
    ],
  );
}

class _TestAuthCubit extends AuthCubit {
  _TestAuthCubit() : super(AuthRemoteDataSource(Dio()));

  void authenticate() => emit(
    const AuthAuthenticated(
      UserModel(
        id: 1,
        name: 'Employee',
        email: 'employee@example.test',
        status: 'active',
        roles: ['employee'],
        permissions: [],
      ),
    ),
  );
}

class _FakeNotificationRemoteDataSource extends NotificationRemoteDataSource {
  _FakeNotificationRemoteDataSource({this.fail = false}) : super(Dio());

  final bool fail;
  int? markedReadId;

  @override
  Future<AppNotificationModel> getNotification(int id) async {
    if (fail) throw StateError('notification unavailable');
    return AppNotificationModel(
      id: id,
      type: 'announcement.published',
      title: 'Announcement',
      body: 'Announcement body',
      context: const {'announcement_id': 42},
      createdAt: '2026-10-25T00:00:00Z',
    );
  }

  @override
  Future<AppNotificationModel> markRead(int id) async {
    markedReadId = id;
    return getNotification(id);
  }
}

class _FakePushNotificationService implements PushNotificationService {
  _FakePushNotificationService({this.initialMessage});

  final PushMessage? initialMessage;
  final StreamController<PushMessage> messageController =
      StreamController<PushMessage>.broadcast();

  void add(PushMessage message) => messageController.add(message);

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> initializeAndGetToken() async => null;

  @override
  Future<PushMessage?> getInitialMessage() async => initialMessage;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<PushMessage> get messages => messageController.stream;

  @override
  Future<void> dispose() async {
    await messageController.close();
  }
}
