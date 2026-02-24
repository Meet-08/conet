import 'package:conet_app/feature/notification/domain/repositories/notification_repository.dart';

class WatchNotificationsUseCase {
  final NotificationRepository _repository;

  WatchNotificationsUseCase({required NotificationRepository repository})
    : _repository = repository;

  /// Returns a stream that emits whenever a new POST_LIKE or POST_COMMENT
  /// notification is created for the given [userId].
  Stream<void> call(String userId) {
    return _repository.watchNewNotifications(userId);
  }
}
