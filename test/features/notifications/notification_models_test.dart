import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/notifications/data/models/notification_models.dart';

void main() {
  test('notification parses context and announcement id', () {
    final notification = AppNotificationModel.fromJson({
      'id': 11,
      'type': 'announcement.published',
      'title': 'New announcement',
      'body': 'A new announcement has been published.',
      'context': {'announcement_id': 7},
      'read_at': null,
      'created_at': '2026-10-23T09:00:00+00:00',
    });
    final readNotification = NotificationResponse.fromJson({
      'data': {
        'id': 12,
        'type': 'leave.request.submitted',
        'title': 'Leave submitted',
        'context': {'announcement_id': '7'},
        'read_at': '2026-10-23T10:00:00+00:00',
      },
    }).notification;

    expect(notification.announcementId, 7);
    expect(notification.isRead, isFalse);
    expect(notification.body, 'A new announcement has been published.');
    expect(readNotification.announcementId, 7);
    expect(readNotification.isRead, isTrue);
  });

  test('notification parses leave and attendance deep links', () {
    final leave = AppNotificationModel.fromJson({
      'id': 13,
      'type': 'leave.request.approved',
      'context': {'leave_request_id': '21'},
    });
    final attendance = AppNotificationModel.fromJson({
      'id': 14,
      'type': 'attendance.reminder',
      'context': {'attendance_session_id': 33},
    });

    expect(leave.leaveRequestId, 21);
    expect(leave.attendanceSessionId, isNull);
    expect(attendance.attendanceSessionId, 33);
    expect(attendance.leaveRequestId, isNull);
  });

  test('notification page parses pagination metadata', () {
    final page = NotificationPage.fromJson({
      'data': [
        {'id': 1, 'type': 'announcement.published', 'title': 'One'},
      ],
      'meta': {'current_page': 1, 'per_page': 20, 'total': 1, 'last_page': 1},
    });

    expect(page.notifications, hasLength(1));
    expect(page.notifications.single.title, 'One');
    expect(page.total, 1);
    expect(page.lastPage, 1);
  });
}
