import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventRemoveCohost {
  final EventRepository _repository;

  EventRemoveCohost({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, String>> call({
    required String eventId,
    required String userId,
  }) {
    return _repository.removeCohost(eventId: eventId, userId: userId);
  }
}
