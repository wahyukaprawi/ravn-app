import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/announcements/data/datasources/announcement_remote_datasource.dart';
import 'package:ravn/features/announcements/data/models/announcement_models.dart';
import 'package:ravn/features/announcements/presentation/cubit/announcement_cubit.dart';
import 'package:ravn/features/announcements/presentation/pages/announcements_page.dart';
import 'package:ravn/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:ravn/features/notifications/data/models/notification_models.dart';
import 'package:ravn/features/notifications/presentation/cubit/notification_cubit.dart';
import 'package:ravn/features/notifications/presentation/pages/notifications_page.dart';

void main() {
  testWidgets('announcement list renders and switches to unread', (
    tester,
  ) async {
    final remote = _FakeAnnouncementRemoteDataSource();
    final cubit = AnnouncementCubit(remote);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AnnouncementCubit>.value(
          value: cubit,
          child: const AnnouncementsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Policy update'), findsOneWidget);

    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();

    expect(remote.lastUnreadOnly, isTrue);

    await cubit.close();
  });

  testWidgets('notification list can mark all notifications read', (
    tester,
  ) async {
    final remote = _FakeNotificationRemoteDataSource();
    final cubit = NotificationCubit(remote);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<NotificationCubit>.value(
          value: cubit,
          child: const NotificationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New announcement'), findsOneWidget);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(remote.markAllCalls, 1);
    expect((cubit.state as NotificationLoaded).unreadCount, 0);

    await cubit.close();
  });
}

class _FakeAnnouncementRemoteDataSource extends AnnouncementRemoteDataSource {
  _FakeAnnouncementRemoteDataSource() : super(Dio());

  bool? lastUnreadOnly;

  @override
  Future<AnnouncementPage> getAnnouncements({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    lastUnreadOnly = unreadOnly;

    return const AnnouncementPage(
      announcements: [
        AnnouncementModel(
          id: 1,
          title: 'Policy update',
          status: 'published',
          publishedAt: '2026-10-23T09:00:00+00:00',
        ),
      ],
      currentPage: 1,
      perPage: 20,
      total: 1,
      lastPage: 1,
    );
  }
}

class _FakeNotificationRemoteDataSource extends NotificationRemoteDataSource {
  _FakeNotificationRemoteDataSource() : super(Dio());

  int markAllCalls = 0;

  @override
  Future<NotificationPage> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    return const NotificationPage(
      notifications: [
        AppNotificationModel(
          id: 1,
          type: 'announcement.published',
          title: 'New announcement',
          body: 'A new announcement has been published.',
          context: {'announcement_id': 7},
        ),
      ],
      currentPage: 1,
      perPage: 20,
      total: 1,
      lastPage: 1,
    );
  }

  @override
  Future<int> getUnreadCount() async => 1;

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    return 1;
  }
}
