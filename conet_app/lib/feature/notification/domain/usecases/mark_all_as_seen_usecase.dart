import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/notification/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAllAsSeenUseCase {
  final NotificationRepository _repository;

  MarkAllAsSeenUseCase({required NotificationRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call() {
    return _repository.markAllAsSeen();
  }
}
