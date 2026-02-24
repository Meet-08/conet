/// Watches the notifications table for real-time INSERT events.
abstract class NotificationRealtimeDataSource {
  /// Emits the raw record map for each new notification inserted
  /// for the given [userId].
  Stream<Map<String, dynamic>> watchNewNotifications(String userId);
}
