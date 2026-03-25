import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetById {
  final EventRepository _repository;

  EventGetById({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Event>> call(String eventId) {
    return _repository.getEventById(eventId);
  }
}
