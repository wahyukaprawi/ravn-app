import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/attendance_models.dart';

class AttendanceRemoteDataSource {
  final Dio dio;
  final Uuid uuid;

  AttendanceRemoteDataSource(this.dio, {this.uuid = const Uuid()});

  Future<AttendanceStatusModel> getStatus() async {
    final response = await dio.get(ApiConstants.attendanceStatus);
    return AttendanceStatusModel.fromJson(_map(response.data));
  }

  Future<List<AttendanceSessionModel>> getHistory({
    String scope = 'mine',
    int perPage = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.attendanceHistory,
      queryParameters: {'scope': scope, 'per_page': perPage},
    );
    return AttendanceHistoryResponse.fromJson(_map(response.data)).data;
  }

  Future<String> createChallenge({String? deviceId}) async {
    final response = await dio.post(
      ApiConstants.attendanceChallenges,
      data: {if (deviceId != null && deviceId.isNotEmpty) 'device_id': deviceId},
    );
    final data = _map(_map(response.data)['data']);
    return data['challenge_id']?.toString() ?? '';
  }

  Future<AttendanceSessionModel> checkIn({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required bool mocked,
    required String deviceId,
    required String challengeId,
    required bool faceVerified,
  }) async {
    final response = await dio.post(
      ApiConstants.attendanceCheckIn,
      data: _punchPayload(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        mocked: mocked,
        deviceId: deviceId,
        challengeId: challengeId,
        faceVerified: faceVerified,
      ),
      options: Options(headers: {'Idempotency-Key': uuid.v4()}),
    );
    return _sessionFromResponse(response.data);
  }

  Future<AttendanceSessionModel> checkOut({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required bool mocked,
    required String deviceId,
    required String challengeId,
    required bool faceVerified,
  }) async {
    final response = await dio.post(
      ApiConstants.attendanceCheckOut,
      data: _punchPayload(
        latitude: latitude,
        longitude: longitude,
        accuracyMeters: accuracyMeters,
        mocked: mocked,
        deviceId: deviceId,
        challengeId: challengeId,
        faceVerified: faceVerified,
      ),
      options: Options(headers: {'Idempotency-Key': uuid.v4()}),
    );
    return _sessionFromResponse(response.data);
  }

  Map<String, dynamic> _punchPayload({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required bool mocked,
    required String deviceId,
    required String challengeId,
    required bool faceVerified,
  }) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'mock_location_detected': mocked,
      'device_id': deviceId,
      'face_challenge_id': challengeId,
      'face_verified': faceVerified,
      'source': 'app',
      'device_integrity': {'client': 'flutter'},
    };
  }

  AttendanceSessionModel _sessionFromResponse(Object? body) {
    final data = _map(_map(body)['data']);
    final session = _map(data['session']);
    return AttendanceSessionModel.fromJson(session);
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }
}
