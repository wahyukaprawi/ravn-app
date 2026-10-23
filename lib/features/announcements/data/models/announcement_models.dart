class AnnouncementModel {
  final int id;
  final String title;
  final String status;
  final String? publishedAt;
  final String? readAt;
  final String? createdAt;
  final String? body;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.status,
    this.publishedAt,
    this.readAt,
    this.createdAt,
    this.body,
  });

  bool get isRead => readAt != null;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: _int(json['id']),
      title: _string(json['title']),
      status: _string(json['status']),
      publishedAt: _nullableString(json['published_at']),
      readAt: _nullableString(json['read_at']),
      createdAt: _nullableString(json['created_at']),
      body: _nullableString(json['body']),
    );
  }

  AnnouncementModel copyWith({String? readAt}) {
    return AnnouncementModel(
      id: id,
      title: title,
      status: status,
      publishedAt: publishedAt,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
      body: body,
    );
  }
}

class AnnouncementPage {
  final List<AnnouncementModel> announcements;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const AnnouncementPage({
    required this.announcements,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory AnnouncementPage.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final meta = json['meta'];

    return AnnouncementPage(
      announcements: data is List
          ? data
                .whereType<Map>()
                .map(
                  (item) => AnnouncementModel.fromJson(
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

class AnnouncementResponse {
  final AnnouncementModel announcement;

  const AnnouncementResponse({required this.announcement});

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AnnouncementResponse(
      announcement: AnnouncementModel.fromJson(
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
