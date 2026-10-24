import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class AppConfig {
  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl => resolveBaseUrl();

  static String resolveBaseUrl({
    String? override,
    bool? isWeb,
    bool? isIos,
    bool? isMacOS,
  }) {
    final configured = override ?? _overrideBaseUrl;

    if (configured.isNotEmpty) {
      return configured;
    }

    if ((isWeb ?? kIsWeb) ||
        (isIos ?? Platform.isIOS) ||
        (isMacOS ?? Platform.isMacOS)) {
      return ApiConstants.baseUrlIos;
    }

    return ApiConstants.baseUrl;
  }

  static const bool syntheticFaceVerification = bool.fromEnvironment(
    'RAVN_SYNTHETIC_FACE_VERIFICATION',
  );

  static const String appName = 'Ravn HRMS';
  static const String version = '1.0.0';
}
