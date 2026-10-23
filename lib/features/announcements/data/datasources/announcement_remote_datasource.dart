import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/announcement_models.dart';

class AnnouncementRemoteDataSource {
  final Dio dio;

  AnnouncementRemoteDataSource(this.dio);

  Future<AnnouncementPage> getAnnouncements({
    bool unreadOnly = false,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await dio.get(
      ApiConstants.announcements,
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (unreadOnly) 'unread': 1,
      },
    );

    return AnnouncementPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AnnouncementModel> getAnnouncement(int id) async {
    final response = await dio.get('${ApiConstants.announcements}/$id');

    return AnnouncementResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    ).announcement;
  }

  Future<AnnouncementModel> markRead(int id) async {
    final response = await dio.post('${ApiConstants.announcements}/$id/read');

    return AnnouncementResponse.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    ).announcement;
  }
}
