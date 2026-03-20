import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventGetPublishedEvents {
  final EventRepository _repository;

  EventGetPublishedEvents({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, EventPage>> call({
    int limit = 20,
    String? cursor,
    String? category,
    String? locationType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) {
    return _repository.getPublishedEvents(
      limit: limit,
      cursor: cursor,
      category: category,
      locationType: locationType,
      dateFrom: dateFrom,
      dateTo: dateTo,
      search: search,
    );
  }
}
