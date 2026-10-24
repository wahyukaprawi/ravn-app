import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravn/features/notifications/data/notification_preferences_service.dart';
import 'package:ravn/features/notifications/domain/notification_preferences.dart';

void main() {
  test('loads enabled defaults when no preferences are stored', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = NotificationPreferencesService();

    final preferences = await service.load();

    expect(preferences.pushEnabled, isTrue);
    expect(preferences.announcements, isTrue);
    expect(preferences.leaveUpdates, isTrue);
    expect(preferences.attendanceReminders, isTrue);
  });

  test('persists and reloads every preference', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final service = NotificationPreferencesService();
    const preferences = NotificationPreferences(
      pushEnabled: false,
      announcements: true,
      leaveUpdates: false,
      attendanceReminders: true,
    );

    await service.save(preferences);
    final loaded = await service.load();

    expect(loaded.pushEnabled, isFalse);
    expect(loaded.announcements, isTrue);
    expect(loaded.leaveUpdates, isFalse);
    expect(loaded.attendanceReminders, isTrue);
  });
}
