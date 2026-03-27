import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetRegistrationInfo {
  final EventRepository _repository;

  EventGetRegistrationInfo({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventRegistrationTicket>> call(String eventId) {
    return _repository.getRegistrationInfo(eventId);
  }
}
