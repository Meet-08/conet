import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetRegistrationCountByCollege {
  final EventRepository _repository;

  EventGetRegistrationCountByCollege({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, List<EventRegistrationCount>>> call(
    String eventId,
  ) {
    return _repository.getRegistrationCountByCollege(eventId);
  }
}
