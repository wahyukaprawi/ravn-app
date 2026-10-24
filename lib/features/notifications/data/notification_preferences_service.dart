import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/notification_preferences.dart';

class NotificationPreferencesService {
  final FlutterSecureStorage storage;

  NotificationPreferencesService({FlutterSecureStorage? storage})
    : storage = storage ?? const FlutterSecureStorage();

  Future<NotificationPreferences> load() async {
    return NotificationPreferences(
      pushEnabled: await _readBool('notifications.push_enabled', true),
      announcements: await _readBool('notifications.announcements', true),
      leaveUpdates: await _readBool('notifications.leave_updates', true),
      attendanceReminders: await _readBool(
        'notifications.attendance_reminders',
        true,
      ),
    );
  }

  Future<void> save(NotificationPreferences preferences) async {
    await storage.write(
      key: 'notifications.push_enabled',
      value: preferences.pushEnabled.toString(),
    );
    await storage.write(
      key: 'notifications.announcements',
      value: preferences.announcements.toString(),
    );
    await storage.write(
      key: 'notifications.leave_updates',
      value: preferences.leaveUpdates.toString(),
    );
    await storage.write(
      key: 'notifications.attendance_reminders',
      value: preferences.attendanceReminders.toString(),
    );
  }

  Future<bool> _readBool(String key, bool fallback) async {
    final value = await storage.read(key: key);
    if (value == null) return fallback;
    return value == 'true';
  }
}
