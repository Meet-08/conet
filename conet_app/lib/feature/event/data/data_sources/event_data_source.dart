import 'package:conet_app/feature/event/data/models/event_page_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';

abstract class EventDataSource {
  Future<Event> getEventById(String eventId);

  Future<Event> registerEvent(String eventId);

  Future<Event> publishEvent(EventCreatePayload payload);

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
}
