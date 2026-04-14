import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventPromoteCohost {
  final EventRepository _repository;

  EventPromoteCohost({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventCohost>> call({
    required String eventId,
    required String userId,
  }) {
    return _repository.promoteCohost(eventId: eventId, userId: userId);
  }
}
