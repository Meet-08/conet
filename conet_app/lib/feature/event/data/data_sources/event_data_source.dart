import 'package:conet_app/feature/event/data/models/event_attendance_result_model.dart';
import 'package:conet_app/feature/event/data/models/event_attendees_model.dart';
import 'package:conet_app/feature/event/data/models/event_cohost_model.dart';
import 'package:conet_app/feature/event/data/models/event_page_model.dart';
import 'package:conet_app/feature/event/data/models/event_registration_ticket_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';

abstract class EventDataSource {
  Future<Event> getEventById(String eventId);

  Future<EventRegisterResponse> registerEvent(
    String eventId,
    EventRegistrationPayload payload,
  );

  Future<EventRegisterResponse> registerParticipantForEvent(
    String eventId,
    String participantUserId,
    EventRegistrationPayload payload,
  );

  Future<EventAttendanceResultModel> saveEvent(String eventId);

  Future<Event> publishEvent(EventCreatePayload payload);

  Future<Event> publishDraftById(String eventId);

  Future<Event> updateEventConversationId({
    required String eventId,
    required String conversationId,
  });

  Future<Event> saveEventDraft(EventCreatePayload payload);

  Future<EventPageModel> getPublishedEvents({
    int limit = 20,
    String? cursor,
    String? category,
    String? locationType,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? search,
  });

  Future<EventPageModel> getMyEvents({
    required String type,
    int limit = 20,
    String? cursor,
  });

  Future<EventPageModel> getMyOrganizedEvents({
    String? status,
    int limit = 20,
    String? cursor,
  });

  Future<EventRegistrationTicketModel> getRegistrationInfo(String eventId);

  Future<EventAttendeesModel> getEventAttendees({
    required String eventId,
    String? status,
  });

  Future<List<EventCohostModel>> getCohosts(String eventId);

  Future<EventCohostModel> addCohost({
    required String eventId,
    required String userId,
  });

  Future<String> removeCohost({
    required String eventId,
    required String userId,
  });

  Future<EventCohostModel> promoteCohost({
    required String eventId,
    required String userId,
  });

  Future<EventAttendanceResultModel> markAttendance({
    required String eventId,
    required String userId,
    required String registrationId,
  });
}
