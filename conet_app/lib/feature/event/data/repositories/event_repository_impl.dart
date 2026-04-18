import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/event/data/data_sources/event_data_source.dart';
import 'package:conet_app/feature/event/data/models/event_cohost_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
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
  Future<Either<AppFailure, EventPage>> getMyEvents({
    required String type,
    int limit = 20,
    String? cursor,
  }) {
    return _getResult<EventPage, EventPage>(
      () => _eventDataSource.getMyEvents(
        type: type,
        limit: limit,
        cursor: cursor,
      ),
    );
  }

  @override
  Future<Either<AppFailure, EventPage>> getMyOrganizedEvents({
    String? status,
    String? search,
    int limit = 20,
    String? cursor,
  }) {
    return _getResult<EventPage, EventPage>(
      () => _eventDataSource.getMyOrganizedEvents(
        status: status,
        search: search,
        limit: limit,
        cursor: cursor,
      ),
    );
  }

  @override
  Future<Either<AppFailure, EventRegisterResponse>> registerEvent(
    String eventId,
    EventRegistrationPayload payload,
  ) {
    return _getResult<EventRegisterResponse, EventRegisterResponse>(
      () => _eventDataSource.registerEvent(eventId, payload),
    );
  }

  @override
  Future<Either<AppFailure, EventRegisterResponse>> registerParticipantForEvent(
    String eventId,
    String participantUserId,
    EventRegistrationPayload payload,
  ) {
    return _getResult<EventRegisterResponse, EventRegisterResponse>(
      () => _eventDataSource.registerParticipantForEvent(
        eventId,
        participantUserId,
        payload,
      ),
    );
  }

  @override
  Future<Either<AppFailure, EventAttendanceResult>> saveEvent(String eventId) {
    return _getResult<EventAttendanceResult, EventAttendanceResult>(
      () => _eventDataSource.saveEvent(eventId),
    );
  }

  @override
  Future<Either<AppFailure, Event>> publishEvent(EventCreatePayload payload) {
    return _getResult<Event, Event>(
      () => _eventDataSource.publishEvent(payload),
    );
  }

  @override
  Future<Either<AppFailure, Event>> publishDraftById(String eventId) {
    return _getResult<Event, Event>(
      () => _eventDataSource.publishDraftById(eventId),
    );
  }

  @override
  Future<Either<AppFailure, Event>> updateEventConversationId({
    required String eventId,
    required String conversationId,
  }) {
    return _getResult<Event, Event>(
      () => _eventDataSource.updateEventConversationId(
        eventId: eventId,
        conversationId: conversationId,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Event>> saveEventDraft(EventCreatePayload payload) {
    return _getResult<Event, Event>(
      () => _eventDataSource.saveEventDraft(payload),
    );
  }

  @override
  Future<Either<AppFailure, EventRegistrationTicket>> getRegistrationInfo(
    String eventId,
  ) {
    return _getResult<EventRegistrationTicket, EventRegistrationTicket>(
      () => _eventDataSource.getRegistrationInfo(eventId),
    );
  }

  @override
  Future<Either<AppFailure, EventAttendees>> getEventAttendees({
    required String eventId,
    String? status,
  }) {
    return _getResult<EventAttendees, EventAttendees>(
      () =>
          _eventDataSource.getEventAttendees(eventId: eventId, status: status),
    );
  }

  @override
  Future<Either<AppFailure, List<EventCohost>>> getCohosts(String eventId) {
    return _getResult<List<EventCohostModel>, List<EventCohost>>(
      () => _eventDataSource.getCohosts(eventId),
      mapper: (cohosts) => cohosts.cast<EventCohost>().toList(growable: false),
    );
  }

  @override
  Future<Either<AppFailure, EventCohost>> addCohost({
    required String eventId,
    required String userId,
  }) {
    return _getResult<EventCohostModel, EventCohost>(
      () => _eventDataSource.addCohost(eventId: eventId, userId: userId),
    );
  }

  @override
  Future<Either<AppFailure, String>> removeCohost({
    required String eventId,
    required String userId,
  }) {
    return _getResult<String, String>(
      () => _eventDataSource.removeCohost(eventId: eventId, userId: userId),
    );
  }

  @override
  Future<Either<AppFailure, EventCohost>> promoteCohost({
    required String eventId,
    required String userId,
  }) {
    return _getResult<EventCohostModel, EventCohost>(
      () => _eventDataSource.promoteCohost(eventId: eventId, userId: userId),
    );
  }

  @override
  Future<Either<AppFailure, EventAttendanceResult>> markAttendance({
    required String eventId,
    required String userId,
    required String registrationId,
  }) {
    return _getResult<EventAttendanceResult, EventAttendanceResult>(
      () => _eventDataSource.markAttendance(
        eventId: eventId,
        userId: userId,
        registrationId: registrationId,
      ),
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
