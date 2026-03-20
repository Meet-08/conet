import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventSaveDraft {
  final EventRepository _repository;

  EventSaveDraft({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Event>> call(EventCreatePayload payload) {
    return _repository.saveEventDraft(payload);
  }
}
