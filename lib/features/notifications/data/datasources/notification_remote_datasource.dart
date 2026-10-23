import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/notification_models.dart';

class NotificationRemoteDataSource {
  final Dio dio;

  NotificationRemoteDataSource(this.dio);

  Future<NotificationPage> getNotifications({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.notifications,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (unreadOnly) 'unread': 1,
      },
    );

    return NotificationPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<int> getUnreadCount() async {
    final page = await getNotifications(unreadOnly: true, perPage: 1);
    return page.total;
  }

  Future<AppNotificationModel> markRead(int id) async {
    final response = await dio.post('${ApiConstants.notifications}/$id/read');

    return NotificationResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    ).notification;
  }

  Future<int> markAllRead() async {
    final response = await dio.post('${ApiConstants.notifications}/read-all');
    final data = Map<String, dynamic>.from(response.data as Map);
    final updated = data['updated'];

    if (updated is int) return updated;
    if (updated is num) return updated.toInt();
    return int.tryParse(updated?.toString() ?? '') ?? 0;
  }
}
