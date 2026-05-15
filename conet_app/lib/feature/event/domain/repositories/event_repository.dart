import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class EventRepository {
  Future<Either<AppFailure, Event>> getEventById(String eventId);

  Future<Either<AppFailure, EventRegisterResponse>> registerEvent(
    String eventId,
    EventRegistrationPayload payload,
  );

  Future<Either<AppFailure, EventAttendanceResult>> saveEvent(String eventId);

  Future<Either<AppFailure, Event>> publishEvent(EventCreatePayload payload);
  Future<Either<AppFailure, Event>> updateEvent(
    String eventId,
    EventCreatePayload payload,
  );
  Future<Either<AppFailure, Event>> updateDraftEvent(
    String eventId,
    EventCreatePayload payload,
  );

  Future<Either<AppFailure, Event>> publishDraftById(String eventId);

  Future<Either<AppFailure, Event>> updateEventConversationId({
    required String eventId,
    required String conversationId,
  });

  Future<Either<AppFailure, Event>> saveEventDraft(EventCreatePayload payload);

  Future<Either<AppFailure, Unit>> setupOrganizerResources({
    required String eventId,
    required List<String> cohostUserIds,
    required bool createEventConversation,
    String? conversationId,
  });

  Future<Either<AppFailure, EventPage>> getPublishedEvents({
    int limit = 20,
    String? cursor,
    String? category,
    String? locationType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });

  Future<Either<AppFailure, EventPage>> getMyEvents({
    required String type,
    int limit = 20,
    String? cursor,
  });

  Future<Either<AppFailure, EventPage>> getMyOrganizedEvents({
    String? status,
    String? timeline,
    DateTime? dateFrom,
    DateTime? dateTo,
    int limit = 20,
    String? cursor,
  });

  Future<Either<AppFailure, EventRegistrationTicket>> getRegistrationInfo(
    String eventId,
  );

  Future<Either<AppFailure, EventAttendees>> getEventAttendees({
    required String eventId,
    String? status,
  });

  Future<Either<AppFailure, EventAttendanceResult>> markAttendance({
    required String eventId,
    required String userId,
    required String registrationId,
  });
}
