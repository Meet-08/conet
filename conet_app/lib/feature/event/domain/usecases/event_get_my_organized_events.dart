import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetMyOrganizedEvents {
  final EventRepository _repository;

  EventGetMyOrganizedEvents({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventPage>> call({
    String? status,
    int limit = 20,
    String? cursor,
  }) {
    return _repository.getMyOrganizedEvents(
      status: status,
      limit: limit,
      cursor: cursor,
    );
  }
}
