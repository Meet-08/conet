import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetAttendees {
  final EventRepository _repository;

  EventGetAttendees({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventAttendees>> call({
    required String eventId,
    String? status,
  }) {
    return _repository.getEventAttendees(eventId: eventId, status: status);
  }
}
