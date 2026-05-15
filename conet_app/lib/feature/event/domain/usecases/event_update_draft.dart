import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventUpdateDraft {
  final EventRepository _repository;

  EventUpdateDraft({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Event>> call(
    String eventId,
    EventCreatePayload payload,
  ) {
    return _repository.updateDraftEvent(eventId, payload);
  }
}
