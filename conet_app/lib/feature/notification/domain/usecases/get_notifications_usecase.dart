import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/notification/domain/entities/notification_page.dart';
import 'package:conet_app/feature/notification/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, NotificationPage>> call({
    int limit = 20,
    String? cursor,
  }) {
    return _repository.getNotifications(limit: limit, cursor: cursor);
  }
}
