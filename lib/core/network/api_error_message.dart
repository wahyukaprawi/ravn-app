import 'package:dio/dio.dart';

String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final envelope = data['error'];
      if (envelope is Map && envelope['message'] != null) {
        return envelope['message'].toString();
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check your connection and try again.';
      default:
        final status = error.response?.statusCode;
        if (status == 401) {
          return 'Your session has expired. Please sign in again.';
        }
        if (status == 403) {
          return 'You do not have permission to perform this action.';
        }
        if (status == 429) {
          return 'Too many attempts. Please try again later.';
        }
    }
  }

  return error.toString();
}
