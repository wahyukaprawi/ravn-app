import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class AppConfig {
  static String get baseUrl {
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      return ApiConstants.baseUrlIos;
    }
    return ApiConstants.baseUrl;
  }

  static const String appName = 'Ravn HRMS';
  static const String version = '1.0.0';
}
