import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/notification/domain/entities/notification_page.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class NotificationRepository {
  Future<Either<AppFailure, NotificationPage>> getNotifications({
    int limit = 20,
    String? cursor,
  });

  Future<Either<AppFailure, Unit>> markAllAsSeen();

  /// Emits a signal whenever a new POST_LIKE or POST_COMMENT notification
  /// is inserted for the given user. NEW_MESSAGE notifications are excluded.
  Stream<void> watchNewNotifications(String userId);
}
