import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventAddCohost {
  final EventRepository _repository;

  EventAddCohost({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventCohost>> call({
    required String eventId,
    required String userId,
  }) {
    return _repository.addCohost(eventId: eventId, userId: userId);
  }
}
