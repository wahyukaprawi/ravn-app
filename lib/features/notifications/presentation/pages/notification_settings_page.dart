import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/notification_preferences_service.dart';
import '../../domain/notification_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationPreferencesService _service =
      getIt<NotificationPreferencesService>();

  NotificationPreferences? _preferences;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await _service.load();
    if (!mounted) return;
    setState(() => _preferences = preferences);
  }

  Future<void> _update(NotificationPreferences preferences) async {
    setState(() {
      _preferences = preferences;
      _saving = true;
    });

    await _service.save(preferences);

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final preferences = _preferences;

    return Scaffold(
      appBar: AppBar(title: const Text('Notification settings')),
      body: preferences == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: preferences.pushEnabled,
                        onChanged: _saving
                            ? null
                            : (value) => _update(
                                preferences.copyWith(pushEnabled: value),
                              ),
                        secondary: const Icon(HeroiconsOutline.devicePhoneMobile),
                        title: const Text('Push notifications'),
                        subtitle: const Text(
                          'Receive alerts on this device when signed in.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: preferences.announcements,
                        onChanged: _saving
                            ? null
                            : (value) => _update(
                                preferences.copyWith(announcements: value),
                              ),
                        secondary: const Icon(HeroiconsOutline.megaphone),
                        title: const Text('Announcements'),
                        subtitle: const Text(
                          'Company announcements and important updates.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: preferences.leaveUpdates,
                        onChanged: _saving
                            ? null
                            : (value) => _update(
                                preferences.copyWith(leaveUpdates: value),
                              ),
                        secondary: const Icon(HeroiconsOutline.calendarDays),
                        title: const Text('Leave updates'),
                        subtitle: const Text(
                          'Approval decisions and workflow reminders.',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: preferences.attendanceReminders,
                        onChanged: _saving
                            ? null
                            : (value) => _update(
                                preferences.copyWith(
                                  attendanceReminders: value,
                                ),
                              ),
                        secondary: const Icon(HeroiconsOutline.clock),
                        title: const Text('Attendance reminders'),
                        subtitle: const Text(
                          'Clock-in and clock-out reminders for your schedule.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        HeroiconsOutline.informationCircle,
                        size: 18,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivery depends on the device notification permission and the organisation push configuration. In-app notifications remain available in the bell menu.',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
