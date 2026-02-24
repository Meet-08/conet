import 'package:conet_app/feature/notification/data/models/notification_page_model.dart';

abstract class NotificationDataSource {
  /// Fetches a page of notifications from the backend.
  Future<NotificationPageModel> getNotifications({
    int limit = 20,
    String? cursor,
  });

  /// Marks all unseen notifications as seen.
  Future<void> markAllAsSeen();
}
