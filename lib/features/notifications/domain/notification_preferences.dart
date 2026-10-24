class NotificationPreferences {
  final bool pushEnabled;
  final bool announcements;
  final bool leaveUpdates;
  final bool attendanceReminders;

  const NotificationPreferences({
    required this.pushEnabled,
    required this.announcements,
    required this.leaveUpdates,
    required this.attendanceReminders,
  });

  const NotificationPreferences.defaults()
    : pushEnabled = true,
      announcements = true,
      leaveUpdates = true,
      attendanceReminders = true;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? announcements,
    bool? leaveUpdates,
    bool? attendanceReminders,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      announcements: announcements ?? this.announcements,
      leaveUpdates: leaveUpdates ?? this.leaveUpdates,
      attendanceReminders: attendanceReminders ?? this.attendanceReminders,
    );
  }
}
