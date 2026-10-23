import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/notifications/data/datasources/notification_remote_datasource.dart';
import 'package:ravn/features/notifications/data/models/notification_models.dart';
import 'package:ravn/features/notifications/presentation/cubit/notification_cubit.dart';

void main() {
  group('NotificationCubit', () {
    test('loads notifications and the unread count', () async {
      final remote = _FakeNotificationRemoteDataSource(_notifications);
      final cubit = NotificationCubit(remote);

      await cubit.load();

      final loaded = cubit.state as NotificationLoaded;
      expect(loaded.notifications, hasLength(2));
      expect(loaded.unreadCount, 1);
      expect(loaded.total, 2);

      await cubit.close();
    });

    test('marks one notification read without losing the list', () async {
      final remote = _FakeNotificationRemoteDataSource(_notifications);
      final cubit = NotificationCubit(remote);

      await cubit.load();
      await cubit.markRead(1);

      final loaded = cubit.state as NotificationLoaded;
      expect(loaded.notifications.first.isRead, isTrue);
      expect(loaded.unreadCount, 0);
      expect(remote.markedReadIds, [1]);

      await cubit.close();
    });

    test('marks all notifications read and clears the unread filter', () async {
      final remote = _FakeNotificationRemoteDataSource(_notifications);
      final cubit = NotificationCubit(remote);

      await cubit.setUnreadOnly(true);
      expect((cubit.state as NotificationLoaded).notifications, hasLength(1));

      await cubit.markAllRead();

      final loaded = cubit.state as NotificationLoaded;
      expect(loaded.notifications, isEmpty);
      expect(loaded.total, 0);
      expect(loaded.unreadCount, 0);
      expect(remote.markAllCalls, 1);

      await cubit.close();
    });

    test(
      'removes a notification from the unread list after reading it',
      () async {
        final remote = _FakeNotificationRemoteDataSource(_notifications);
        final cubit = NotificationCubit(remote);

        await cubit.setUnreadOnly(true);
        await cubit.markRead(1);

        final loaded = cubit.state as NotificationLoaded;
        expect(loaded.notifications, isEmpty);
        expect(loaded.total, 0);
        expect(loaded.unreadCount, 0);

        await cubit.close();
      },
    );

    test('surfaces a load failure', () async {
      final remote = _FakeNotificationRemoteDataSource(
        _notifications,
        failLoad: true,
      );
      final cubit = NotificationCubit(remote);

      await cubit.load();

      expect(cubit.state, isA<NotificationError>());

      await cubit.close();
    });
  });
}

const _notifications = [
  AppNotificationModel(
    id: 1,
    type: 'announcement.published',
    title: 'New announcement',
    body: 'A new announcement has been published.',
    context: {'announcement_id': 7},
    createdAt: '2026-10-23T09:00:00+00:00',
  ),
  AppNotificationModel(
    id: 2,
    type: 'leave.request.submitted',
    title: 'Leave submitted',
    body: 'Your leave request was submitted.',
    readAt: '2026-10-23T10:00:00+00:00',
    createdAt: '2026-10-23T08:00:00+00:00',
  ),
];

class _FakeNotificationRemoteDataSource extends NotificationRemoteDataSource {
  _FakeNotificationRemoteDataSource(this.notifications, {this.failLoad = false})
    : super(Dio());

  final List<AppNotificationModel> notifications;
  final bool failLoad;
  int markAllCalls = 0;
  final List<int> markedReadIds = [];

  @override
  Future<NotificationPage> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    if (failLoad) throw StateError('network down');

    final filtered = unreadOnly
        ? notifications.where((item) => !item.isRead).toList()
        : notifications;

    return NotificationPage(
      notifications: filtered,
      currentPage: 1,
      perPage: 20,
      total: filtered.length,
      lastPage: 1,
    );
  }

  @override
  Future<int> getUnreadCount() async {
    return notifications.where((item) => !item.isRead).length;
  }

  @override
  Future<AppNotificationModel> markRead(int id) async {
    markedReadIds.add(id);
    final notification = notifications.firstWhere((item) => item.id == id);
    return notification.copyWith(readAt: '2026-10-23T10:30:00+00:00');
  }

  @override
  Future<int> markAllRead() async {
    markAllCalls++;
    return notifications.where((item) => !item.isRead).length;
  }
}
