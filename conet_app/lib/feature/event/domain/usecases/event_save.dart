import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventSave {
  final EventRepository _repository;

  EventSave({required EventRepository repository}) : _repository = repository;

  Future<Either<AppFailure, EventAttendanceResult>> call(String eventId) {
    return _repository.saveEvent(eventId);
  }
}
