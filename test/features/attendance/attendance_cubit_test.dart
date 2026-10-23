import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:ravn/features/attendance/data/models/attendance_models.dart';
import 'package:ravn/features/attendance/domain/attendance_location_service.dart';
import 'package:ravn/features/attendance/domain/device_identity_service.dart';
import 'package:ravn/features/attendance/domain/face_verification_service.dart';
import 'package:ravn/features/attendance/presentation/cubit/attendance_cubit.dart';

void main() {
  group('AttendanceCubit', () {
    test('loads today status and history', () async {
      final remote = _FakeAttendanceRemoteDataSource();
      final cubit = AttendanceCubit(
        remote,
        const _FakeLocationService(),
        const _FakeFaceVerificationService(true),
        const _FakeDeviceIdentityService(),
      );

      final states = <AttendanceState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.load();
      await Future<void>.delayed(Duration.zero);

      expect(states.first, isA<AttendanceLoading>());
      final loaded = states.last;
      expect(loaded, isA<AttendanceLoaded>());
      expect((loaded as AttendanceLoaded).status.canCheckIn, isTrue);
      expect(loaded.history, hasLength(1));

      await subscription.cancel();
      await cubit.close();
    });

    test('does not call the API when face verification is unavailable', () async {
      final remote = _FakeAttendanceRemoteDataSource();
      final cubit = AttendanceCubit(
        remote,
        const _FakeLocationService(),
        const _FakeFaceVerificationService(false),
        const _FakeDeviceIdentityService(),
      );

      await cubit.load();
      await cubit.punch(checkIn: true);

      final loaded = cubit.state as AttendanceLoaded;
      expect(remote.checkInCalls, 0);
      expect(loaded.isPunching, isFalse);
      expect(loaded.noticeIsError, isTrue);
      expect(loaded.notice, contains('Face verification is not configured'));

      await cubit.close();
    });

    test('records check-in and reloads the latest status', () async {
      final remote = _FakeAttendanceRemoteDataSource();
      final cubit = AttendanceCubit(
        remote,
        const _FakeLocationService(),
        const _FakeFaceVerificationService(true),
        const _FakeDeviceIdentityService(),
      );

      await cubit.load();
      await cubit.punch(checkIn: true);

      final loaded = cubit.state as AttendanceLoaded;
      expect(remote.checkInCalls, 1);
      expect(remote.lastIdempotencyKey, isNotNull);
      expect(remote.lastMocked, isFalse);
      expect(loaded.isPunching, isFalse);
      expect(loaded.notice, 'Checked in.');
      expect(loaded.status.session?.checkInEvent?.eventType, 'check_in');

      await cubit.close();
    });
  });
}

class _FakeAttendanceRemoteDataSource extends AttendanceRemoteDataSource {
  _FakeAttendanceRemoteDataSource() : super(Dio());

  int checkInCalls = 0;
  String? lastIdempotencyKey;
  bool? lastMocked;

  static const _location = {
    'id': 1,
    'code': 'HQ',
    'name': 'Head Office',
    'timezone': 'Asia/Jakarta',
    'radius_meters': 100,
    'active': true,
  };

  static const _schedule = {
    'id': 3,
    'name': 'Day shift',
    'effective_from': '2024-01-01',
    'effective_to': null,
    'days': [1, 2, 3, 4, 5],
    'start_time': '09:00:00',
    'end_time': '17:00:00',
    'overnight': false,
    'late_grace_minutes': 0,
    'early_departure_grace_minutes': 0,
    'active': true,
    'location': _location,
  };

  Map<String, dynamic> get _sessionJson => {
    'id': 7,
    'work_date': '2026-06-15',
    'timezone': 'Asia/Jakarta',
    'status': checkInCalls == 0 ? 'open' : 'open',
    'opened_at': '2026-06-15T02:00:00+00:00',
    'closed_at': null,
    'scheduled_start_at': '2026-06-15T02:00:00+00:00',
    'scheduled_end_at': '2026-06-15T10:00:00+00:00',
    'late_minutes': 0,
    'early_departure_minutes': 0,
    'flags': const [],
    'schedule': _schedule,
    'location': _location,
    'events': checkInCalls == 0
        ? const []
        : [
            {
              'id': 12,
              'event_type': 'check_in',
              'occurred_at': '2026-06-15T02:00:00+00:00',
              'source': 'app',
              'verification_status': 'claimed',
              'face_verified': true,
              'distance_meters': 3,
              'flags': const [],
              'corrected_at': null,
              'correction_id': null,
            },
          ],
  };

  AttendanceSessionModel get _session => AttendanceSessionModel.fromJson(_sessionJson);

  @override
  Future<AttendanceStatusModel> getStatus() async {
    return AttendanceStatusModel.fromJson({
      'data': {
        'work_date': '2026-06-15',
        'timezone': 'Asia/Jakarta',
        'scheduled_start_at': '2026-06-15T02:00:00+00:00',
        'scheduled_end_at': '2026-06-15T10:00:00+00:00',
        'is_workday': true,
        'can_check_in': checkInCalls == 0,
        'can_check_out': checkInCalls > 0,
        'schedule': _schedule,
        'location': _location,
        'session': checkInCalls == 0 ? null : _sessionJson,
      },
    });
  }

  @override
  Future<List<AttendanceSessionModel>> getHistory({
    String scope = 'mine',
    int perPage = 20,
  }) async {
    return [_session];
  }

  @override
  Future<String> createChallenge({String? deviceId}) async {
    return 'challenge-1';
  }

  @override
  Future<AttendanceSessionModel> checkIn({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required bool mocked,
    required String deviceId,
    required String challengeId,
    required bool faceVerified,
  }) async {
    checkInCalls++;
    lastMocked = mocked;
    lastIdempotencyKey = 'generated-by-test';
    return _session;
  }
}

class _FakeLocationService implements AttendanceLocationService {
  const _FakeLocationService();

  @override
  Future<DeviceLocation> currentLocation() async {
    return const DeviceLocation(
      latitude: -6.2,
      longitude: 106.8,
      accuracyMeters: 8,
      mocked: false,
    );
  }
}

class _FakeFaceVerificationService implements FaceVerificationService {
  final bool result;

  const _FakeFaceVerificationService(this.result);

  @override
  Future<bool> verify(String challengeId) async => result;
}

class _FakeDeviceIdentityService implements DeviceIdentityService {
  const _FakeDeviceIdentityService();

  @override
  Future<String> getOrCreate() async => 'device-1';
}
