class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  void setNotificationCallback(void Function(String, String) callback) {
    // Stub implementation - does nothing for now
  }

  void initializeGlobalReminderChecking() {
    // Stub implementation - does nothing for now
    print('Notification service initialized (stub)');
  }
}
