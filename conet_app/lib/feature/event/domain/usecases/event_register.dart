import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventRegister {
  final EventRepository _repository;

  EventRegister({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventRegisterResponse>> call(
    String eventId,
    EventRegistrationPayload payload,
  ) {
    return _repository.registerEvent(eventId, payload);
  }
}
