import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetMyEvents {
  final EventRepository _repository;

  EventGetMyEvents({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventPage>> call({
    required String type,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.getMyEvents(type: type, limit: limit, cursor: cursor);
  }
}
