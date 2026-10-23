import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/attendance/data/models/attendance_models.dart';

void main() {
  test('attendance status parses the schedule, session and privacy-safe event', () {
    final status = AttendanceStatusModel.fromJson({
      'data': {
        'work_date': '2026-06-15',
        'timezone': 'Asia/Jakarta',
        'scheduled_start_at': '2026-06-15T02:00:00+00:00',
        'scheduled_end_at': '2026-06-15T10:00:00+00:00',
        'is_workday': true,
        'can_check_in': false,
        'can_check_out': true,
        'schedule': {
          'id': 3,
          'name': 'Day shift',
          'effective_from': '2024-01-01',
          'effective_to': null,
          'days': [1, 2, 3, 4, 5],
          'start_time': '09:00:00',
          'end_time': '17:00:00',
          'overnight': false,
          'late_grace_minutes': 5,
          'early_departure_grace_minutes': 5,
          'active': true,
          'location': {
            'id': 1,
            'code': 'HQ',
            'name': 'Head Office',
            'timezone': 'Asia/Jakarta',
            'radius_meters': 100,
            'active': true,
          },
        },
        'location': {
          'id': 1,
          'code': 'HQ',
          'name': 'Head Office',
          'timezone': 'Asia/Jakarta',
          'radius_meters': 100,
          'active': true,
        },
        'session': {
          'id': 9,
          'work_date': '2026-06-15',
          'timezone': 'Asia/Jakarta',
          'status': 'open',
          'opened_at': '2026-06-15T02:00:00+00:00',
          'closed_at': null,
          'scheduled_start_at': '2026-06-15T02:00:00+00:00',
          'scheduled_end_at': '2026-06-15T10:00:00+00:00',
          'late_minutes': 5,
          'early_departure_minutes': 0,
          'flags': ['late'],
          'events': [
            {
              'id': 11,
              'event_type': 'check_in',
              'occurred_at': '2026-06-15T02:05:00+00:00',
              'source': 'app',
              'verification_status': 'claimed',
              'face_verified': true,
              'distance_meters': 12.4,
              'flags': ['late'],
              'corrected_at': null,
              'correction_id': null,
            },
          ],
        },
      },
    });

    expect(status.workDate, '2026-06-15');
    expect(status.schedule?.name, 'Day shift');
    expect(status.schedule?.days, [1, 2, 3, 4, 5]);
    expect(status.session?.checkInEvent?.eventType, 'check_in');
    expect(status.session?.lateMinutes, 5);
    expect(status.canCheckOut, isTrue);
    expect(status.location?.name, 'Head Office');
  });

  test('attendance history ignores malformed rows and keeps flags', () {
    final history = AttendanceHistoryResponse.fromJson({
      'data': [
        {
          'id': 2,
          'work_date': '2026-06-14',
          'timezone': 'Asia/Jakarta',
          'status': 'closed',
          'late_minutes': 0,
          'early_departure_minutes': 10,
          'flags': ['early_departure'],
          'events': [],
        },
        'not-a-row',
      ],
    });

    expect(history.data, hasLength(1));
    expect(history.data.single.status, 'closed');
    expect(history.data.single.flags, ['early_departure']);
    expect(history.data.single.earlyDepartureMinutes, 10);
  });
}
