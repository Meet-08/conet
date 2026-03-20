import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventPublish {
  final EventRepository _repository;

  EventPublish({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Event>> call(EventCreatePayload payload) {
    return _repository.publishEvent(payload);
  }
}
