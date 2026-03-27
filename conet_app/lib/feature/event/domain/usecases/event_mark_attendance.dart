import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventMarkAttendance {
  final EventRepository _repository;

  EventMarkAttendance({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventAttendanceResult>> call({
    required String eventId,
    required String userId,
    required String registrationId,
  }) {
    return _repository.markAttendance(
      eventId: eventId,
      userId: userId,
      registrationId: registrationId,
    );
  }
}
