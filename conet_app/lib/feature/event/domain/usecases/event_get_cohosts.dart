import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetCohosts {
  final EventRepository _repository;

  EventGetCohosts({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, List<EventCohost>>> call(String eventId) {
    return _repository.getCohosts(eventId);
  }
}
