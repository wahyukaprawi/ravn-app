import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/core/network/api_error_message.dart';

void main() {
  test('prefers the API error envelope message', () {
    final options = RequestOptions(path: '/auth/login');
    final error = DioException(
      requestOptions: options,
      response: Response(
        requestOptions: options,
        statusCode: 401,
        data: {
          'error': {
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password.',
          },
        },
      ),
    );

    expect(apiErrorMessage(error), 'Invalid email or password.');
  });

  test('maps a timeout to an actionable message', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/leave/requests'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(apiErrorMessage(error), contains('took too long'));
  });

  test('maps a connection failure without leaking the raw exception', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/leave/requests'),
      type: DioExceptionType.connectionError,
    );

    expect(apiErrorMessage(error), contains('Cannot reach the server'));
  });
}
