class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';
  static const String baseUrlIos = 'http://localhost:8080/api/v1';
  static const String health = '/health';

  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String mfaEnroll = '/auth/mfa/enroll';
  static const String mfaConfirm = '/auth/mfa/confirm';
  static const String mfaVerify = '/auth/mfa/verify';
  static const String mfaStepUp = '/auth/mfa/step-up';
  static const String me = '/me';
  static const String sessions = '/me/sessions';

  static const String attendanceStatus = '/attendance/status';
  static const String attendanceHistory = '/attendance/history';
  static const String attendanceChallenges = '/attendance/challenges';
  static const String attendanceCheckIn = '/attendance/check-in';
  static const String attendanceCheckOut = '/attendance/check-out';

  static const String leaveTypes = '/leave/types';
  static const String leaveBalances = '/leave/balances';
  static const String leaveRequests = '/leave/requests';
  static const String leaveApprovals = '/leave/approvals';
  static const String leaveCancellations = '/leave/cancellations';

  static const String announcements = '/announcements';
  static const String notifications = '/notifications';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
