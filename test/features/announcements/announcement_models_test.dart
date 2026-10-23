import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/announcements/data/models/announcement_models.dart';

void main() {
  test('announcement summary and detail parse read state and body', () {
    final summary = AnnouncementModel.fromJson({
      'id': 7,
      'title': 'Policy update',
      'status': 'published',
      'published_at': '2026-10-23T09:00:00+00:00',
      'read_at': null,
      'created_at': '2026-10-23T08:00:00+00:00',
    });
    final detail = AnnouncementResponse.fromJson({
      'data': {
        'id': 7,
        'title': 'Policy update',
        'status': 'published',
        'published_at': '2026-10-23T09:00:00+00:00',
        'read_at': '2026-10-23T10:00:00+00:00',
        'body': 'The handbook has been updated.',
      },
    }).announcement;

    expect(summary.id, 7);
    expect(summary.isRead, isFalse);
    expect(summary.body, isNull);
    expect(detail.body, 'The handbook has been updated.');
    expect(detail.isRead, isTrue);
  });

  test('announcement page parses pagination metadata', () {
    final page = AnnouncementPage.fromJson({
      'data': [
        {'id': 1, 'title': 'First', 'status': 'published', 'read_at': null},
        'malformed',
      ],
      'meta': {'current_page': 2, 'per_page': 10, 'total': 12, 'last_page': 2},
    });

    expect(page.announcements, hasLength(1));
    expect(page.announcements.single.title, 'First');
    expect(page.currentPage, 2);
    expect(page.total, 12);
    expect(page.lastPage, 2);
  });
}
