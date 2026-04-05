import 'package:conet_app/feature/event/data/models/event_attendance_result_model.dart';
import 'package:conet_app/feature/event/data/models/event_page_model.dart';
import 'package:conet_app/feature/event/data/models/event_registration_ticket_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';

abstract class EventDataSource {
  Future<Event> getEventById(String eventId);

  Future<Event> registerEvent(String eventId, EventRegistrationPayload payload);

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

  Future<EventAttendanceResultModel> markAttendance({
    required String eventId,
    required String userId,
    required String registrationId,
  });
}
