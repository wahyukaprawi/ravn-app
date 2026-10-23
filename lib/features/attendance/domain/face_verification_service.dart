import '../../../core/config/app_config.dart';

abstract class FaceVerificationService {
  Future<bool> verify(String challengeId);
}

class BuildConfiguredFaceVerificationService
    implements FaceVerificationService {
  @override
  Future<bool> verify(String challengeId) async {
    return AppConfig.syntheticFaceVerification;
  }
}
