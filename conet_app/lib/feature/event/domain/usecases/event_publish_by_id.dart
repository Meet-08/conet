import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventPublishById {
  final EventRepository _repository;

  EventPublishById({required EventRepository repository})
      : _repository = repository;

  Future<Either<AppFailure, Event>> call(String eventId) {
    return _repository.publishDraftById(eventId);
  }
}
