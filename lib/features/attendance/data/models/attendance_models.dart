class AttendanceLocationModel {
  final int id;
  final String code;
  final String name;
  final String timezone;
  final int radiusMeters;
  final bool active;

  const AttendanceLocationModel({
    required this.id,
    required this.code,
    required this.name,
    required this.timezone,
    required this.radiusMeters,
    required this.active,
  });

  factory AttendanceLocationModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLocationModel(
      id: _int(json['id']),
      code: _string(json['code']),
      name: _string(json['name']),
      timezone: _string(json['timezone'], fallback: 'UTC'),
      radiusMeters: _int(json['radius_meters']),
      active: json['active'] == true,
    );
  }
}

class AttendanceScheduleModel {
  final int id;
  final String? name;
  final String? effectiveFrom;
  final String? effectiveTo;
  final List<int> days;
  final String startTime;
  final String endTime;
  final bool overnight;
  final int lateGraceMinutes;
  final int earlyDepartureGraceMinutes;
  final bool active;
  final AttendanceLocationModel? location;

  const AttendanceScheduleModel({
    required this.id,
    required this.name,
    required this.effectiveFrom,
    required this.effectiveTo,
    required this.days,
    required this.startTime,
    required this.endTime,
    required this.overnight,
    required this.lateGraceMinutes,
    required this.earlyDepartureGraceMinutes,
    required this.active,
    required this.location,
  });

  factory AttendanceScheduleModel.fromJson(Map<String, dynamic> json) {
    final location = _map(json['location']);

    return AttendanceScheduleModel(
      id: _int(json['id']),
      name: _nullableString(json['name']),
      effectiveFrom: _nullableString(json['effective_from']),
      effectiveTo: _nullableString(json['effective_to']),
      days: _intList(json['days']),
      startTime: _string(json['start_time']),
      endTime: _string(json['end_time']),
      overnight: json['overnight'] == true,
      lateGraceMinutes: _int(json['late_grace_minutes']),
      earlyDepartureGraceMinutes: _int(json['early_departure_grace_minutes']),
      active: json['active'] == true,
      location: location == null
          ? null
          : AttendanceLocationModel.fromJson(location),
    );
  }
}

class AttendanceEventModel {
  final int id;
  final String eventType;
  final String occurredAt;
  final String? source;
  final String? verificationStatus;
  final bool faceVerified;
  final double? distanceMeters;
  final List<String> flags;
  final String? correctedAt;
  final int? correctionId;

  const AttendanceEventModel({
    required this.id,
    required this.eventType,
    required this.occurredAt,
    required this.source,
    required this.verificationStatus,
    required this.faceVerified,
    required this.distanceMeters,
    required this.flags,
    required this.correctedAt,
    required this.correctionId,
  });

  factory AttendanceEventModel.fromJson(Map<String, dynamic> json) {
    return AttendanceEventModel(
      id: _int(json['id']),
      eventType: _string(json['event_type']),
      occurredAt: _string(json['occurred_at']),
      source: _nullableString(json['source']),
      verificationStatus: _nullableString(json['verification_status']),
      faceVerified: json['face_verified'] == true,
      distanceMeters: _double(json['distance_meters']),
      flags: _stringList(json['flags']),
      correctedAt: _nullableString(json['corrected_at']),
      correctionId: _nullableInt(json['correction_id']),
    );
  }
}

class AttendanceUserModel {
  final int id;
  final String name;
  final String email;

  const AttendanceUserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory AttendanceUserModel.fromJson(Map<String, dynamic> json) {
    return AttendanceUserModel(
      id: _int(json['id']),
      name: _string(json['name']),
      email: _string(json['email']),
    );
  }
}

class AttendanceSessionModel {
  final int id;
  final AttendanceUserModel? user;
  final String workDate;
  final String timezone;
  final String status;
  final String? openedAt;
  final String? closedAt;
  final String? scheduledStartAt;
  final String? scheduledEndAt;
  final int lateMinutes;
  final int earlyDepartureMinutes;
  final List<String> flags;
  final AttendanceScheduleModel? schedule;
  final AttendanceLocationModel? location;
  final List<AttendanceEventModel> events;

  const AttendanceSessionModel({
    required this.id,
    required this.user,
    required this.workDate,
    required this.timezone,
    required this.status,
    required this.openedAt,
    required this.closedAt,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.lateMinutes,
    required this.earlyDepartureMinutes,
    required this.flags,
    required this.schedule,
    required this.location,
    required this.events,
  });

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final schedule = _map(json['schedule']);
    final location = _map(json['location']);

    return AttendanceSessionModel(
      id: _int(json['id']),
      user: user == null ? null : AttendanceUserModel.fromJson(user),
      workDate: _string(json['work_date']),
      timezone: _string(json['timezone'], fallback: 'UTC'),
      status: _string(json['status']),
      openedAt: _nullableString(json['opened_at']),
      closedAt: _nullableString(json['closed_at']),
      scheduledStartAt: _nullableString(json['scheduled_start_at']),
      scheduledEndAt: _nullableString(json['scheduled_end_at']),
      lateMinutes: _int(json['late_minutes']),
      earlyDepartureMinutes: _int(json['early_departure_minutes']),
      flags: _stringList(json['flags']),
      schedule: schedule == null
          ? null
          : AttendanceScheduleModel.fromJson(schedule),
      location: location == null
          ? null
          : AttendanceLocationModel.fromJson(location),
      events: _mapList(json['events'])
          .map(AttendanceEventModel.fromJson)
          .toList(growable: false),
    );
  }

  AttendanceEventModel? get checkInEvent {
    for (final event in events) {
      if (event.eventType == 'check_in') return event;
    }
    return null;
  }

  AttendanceEventModel? get checkOutEvent {
    for (final event in events) {
      if (event.eventType == 'check_out') return event;
    }
    return null;
  }
}

class AttendanceStatusModel {
  final AttendanceScheduleModel? schedule;
  final AttendanceLocationModel? location;
  final String? workDate;
  final String? timezone;
  final String? scheduledStartAt;
  final String? scheduledEndAt;
  final bool? isWorkday;
  final AttendanceSessionModel? session;
  final bool canCheckIn;
  final bool canCheckOut;
  final String? reason;

  const AttendanceStatusModel({
    required this.schedule,
    required this.location,
    required this.workDate,
    required this.timezone,
    required this.scheduledStartAt,
    required this.scheduledEndAt,
    required this.isWorkday,
    required this.session,
    required this.canCheckIn,
    required this.canCheckOut,
    required this.reason,
  });

  factory AttendanceStatusModel.fromJson(Map<String, dynamic> json) {
    final data = _map(json['data']) ?? json;
    final schedule = _map(data['schedule']);
    final location = _map(data['location']);
    final session = _map(data['session']);

    return AttendanceStatusModel(
      schedule: schedule == null
          ? null
          : AttendanceScheduleModel.fromJson(schedule),
      location: location == null
          ? null
          : AttendanceLocationModel.fromJson(location),
      workDate: _nullableString(data['work_date']),
      timezone: _nullableString(data['timezone']),
      scheduledStartAt: _nullableString(data['scheduled_start_at']),
      scheduledEndAt: _nullableString(data['scheduled_end_at']),
      isWorkday: data['is_workday'] is bool
          ? data['is_workday'] as bool
          : null,
      session: session == null
          ? null
          : AttendanceSessionModel.fromJson(session),
      canCheckIn: data['can_check_in'] == true,
      canCheckOut: data['can_check_out'] == true,
      reason: _nullableString(data['reason']),
    );
  }
}

class AttendanceHistoryResponse {
  final List<AttendanceSessionModel> data;

  const AttendanceHistoryResponse({required this.data});

  factory AttendanceHistoryResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryResponse(
      data: _mapList(json['data'])
          .map(AttendanceSessionModel.fromJson)
          .toList(growable: false),
    );
  }
}

Map<String, dynamic>? _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value
      .map(_map)
      .whereType<Map<String, dynamic>>()
      .toList(growable: false);
}

String _string(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  return value.toString();
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int _int(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _double(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

List<int> _intList(Object? value) {
  if (value is! List) return const [];
  return value
      .map(_int)
      .where((item) => item > 0)
      .toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
