import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetRegistrationCountByCourse {
  final EventRepository _repository;

  EventGetRegistrationCountByCourse({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, List<EventRegistrationCount>>> call(
    String eventId,
  ) {
    return _repository.getRegistrationCountByCourse(eventId);
  }
}
