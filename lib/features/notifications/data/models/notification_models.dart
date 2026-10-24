class AppNotificationModel {
  final int id;
  final String type;
  final String? title;
  final String? body;
  final Map<String, dynamic> context;
  final String? readAt;
  final String? createdAt;

  const AppNotificationModel({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.context = const {},
    this.readAt,
    this.createdAt,
  });

  bool get isRead => readAt != null;

  int? get announcementId {
    final value = context['announcement_id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int? get leaveRequestId => _contextId('leave_request_id');

  int? get attendanceSessionId => _contextId('attendance_session_id');

  int? _contextId(String key) {
    final value = context[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  factory AppNotificationModel.fromJson(Map<String, dynamic> json) {
    final context = json['context'];

    return AppNotificationModel(
      id: _int(json['id']),
      type: _string(json['type']),
      title: _nullableString(json['title']),
      body: _nullableString(json['body']),
      context: context is Map ? Map<String, dynamic>.from(context) : const {},
      readAt: _nullableString(json['read_at']),
      createdAt: _nullableString(json['created_at']),
    );
  }

  AppNotificationModel copyWith({String? readAt}) {
    return AppNotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      context: context,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationPage {
  final List<AppNotificationModel> notifications;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const NotificationPage({
    required this.notifications,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];

    return NotificationPage(
      notifications: data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) => AppNotificationModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      currentPage: meta is Map ? _int(meta['current_page'], fallback: 1) : 1,
      perPage: meta is Map ? _int(meta['per_page'], fallback: 20) : 20,
      total: meta is Map ? _int(meta['total']) : 0,
      lastPage: meta is Map ? _int(meta['last_page'], fallback: 1) : 1,
    );
  }
}

class NotificationResponse {
  final AppNotificationModel notification;

  const NotificationResponse({required this.notification});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return NotificationResponse(
      notification: AppNotificationModel.fromJson(
        data is Map ? Map<String, dynamic>.from(data) : const {},
      ),
    );
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _string(Object? value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}

String? _nullableString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}
