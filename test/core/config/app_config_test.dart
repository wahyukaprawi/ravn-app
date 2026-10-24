import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/core/config/app_config.dart';
import 'package:ravn/core/constants/api_constants.dart';

void main() {
  test('an explicit API base URL overrides every platform default', () {
    const override = 'http://192.168.1.10:8080/api/v1';

    expect(
      AppConfig.resolveBaseUrl(override: override, isIos: true, isMacOS: true),
      override,
    );
    expect(
      AppConfig.resolveBaseUrl(
        override: override,
        isIos: false,
        isMacOS: false,
      ),
      override,
    );
  });

  test('platform defaults are used when no override is configured', () {
    expect(
      AppConfig.resolveBaseUrl(override: '', isIos: true, isMacOS: false),
      ApiConstants.baseUrlIos,
    );
    expect(
      AppConfig.resolveBaseUrl(override: '', isIos: false, isMacOS: true),
      ApiConstants.baseUrlIos,
    );
    expect(
      AppConfig.resolveBaseUrl(override: '', isIos: false, isMacOS: false),
      ApiConstants.baseUrl,
    );
  });
}
