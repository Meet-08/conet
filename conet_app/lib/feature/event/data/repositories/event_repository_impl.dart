import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventRepositoryImpl implements EventRepository {
  final EventDataSource _eventDataSource;

  EventRepositoryImpl({required EventDataSource eventDataSource})
    : _eventDataSource = eventDataSource;

  @override
  Future<Either<AppFailure, Event>> getEventById(String eventId) {
    return _getResult<Event, Event>(
      () => _eventDataSource.getEventById(eventId),
    );
  }

  @override
  Future<Either<AppFailure, EventPage>> getPublishedEvents({
    int limit = 20,
    String? cursor,
    String? category,
    String? locationType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  }) {
    return _getResult<EventPage, EventPage>(
      () => _eventDataSource.getPublishedEvents(
        limit: limit,
        cursor: cursor,
        category: category,
        locationType: locationType,
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: search,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Event>> registerEvent(String eventId) {
    return _getResult<Event, Event>(
      () => _eventDataSource.registerEvent(eventId),
    );
  }

  @override
  Future<Either<AppFailure, Event>> publishEvent(EventCreatePayload payload) {
    return _getResult<Event, Event>(
      () => _eventDataSource.publishEvent(payload),
    );
  }

  @override
  Future<Either<AppFailure, Event>> saveEventDraft(EventCreatePayload payload) {
    return _getResult<Event, Event>(
      () => _eventDataSource.saveEventDraft(payload),
    );
  }

  Future<Either<AppFailure, TResult>> _getResult<TSource, TResult>(
    Future<TSource> Function() fn, {
    TResult Function(TSource value)? mapper,
  }) async {
    try {
      final value = await fn();
      final result = mapper != null ? mapper(value) : value as TResult;
      return Right(result);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
