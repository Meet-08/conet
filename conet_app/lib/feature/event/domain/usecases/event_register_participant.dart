import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventRegisterParticipant {
  final EventRepository _repository;

  EventRegisterParticipant({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventRegisterResponse>> call({
    required String eventId,
    required String participantUserId,
    required EventRegistrationPayload payload,
  }) {
    return _repository.registerParticipantForEvent(
      eventId,
      participantUserId,
      payload,
    );
  }
}
