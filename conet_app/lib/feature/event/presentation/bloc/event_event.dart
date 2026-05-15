part of 'event_bloc.dart';

@immutable
sealed class EventEvent {
  const EventEvent();
}

final class EventFetchPublishedEventsEvent extends EventEvent {
  final String? cursor;
  final String? category;
  final String? locationType;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? search;

  const EventFetchPublishedEventsEvent({
    this.cursor,
    this.category,
    this.locationType,
    this.dateFrom,
    this.dateTo,
    this.search,
  });
}

final class EventFetchMorePublishedEventsEvent extends EventEvent {
  const EventFetchMorePublishedEventsEvent();
}

final class EventFetchMyEventsEvent extends EventEvent {
  final String type;
  final String? cursor;
  final int limit;

  const EventFetchMyEventsEvent({
    required this.type,
    this.cursor,
    this.limit = 20,
  });
}

final class EventFetchMoreMyEventsEvent extends EventEvent {
  const EventFetchMoreMyEventsEvent();
}

final class EventFetchMyOrganizedEventsEvent extends EventEvent {
  final String? status;
  final String? timeline;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? cursor;
  final int limit;

  const EventFetchMyOrganizedEventsEvent({
    this.status,
    this.timeline,
    this.dateFrom,
    this.dateTo,
    this.cursor,
    this.limit = 20,
  });
}

final class EventFetchMoreMyOrganizedEventsEvent extends EventEvent {
  const EventFetchMoreMyOrganizedEventsEvent();
}

final class EventFetchByIdEvent extends EventEvent {
  final String eventId;

  const EventFetchByIdEvent(this.eventId);
}

final class EventRegisterEvent extends EventEvent {
  final String eventId;
  final EventRegistrationPayload payload;

  const EventRegisterEvent(this.eventId, this.payload);
}

final class EventSaveEvent extends EventEvent {
  final String eventId;

  const EventSaveEvent(this.eventId);
}

final class EventPublishEvent extends EventEvent {
  final EventCreatePayload payload;
  final bool shouldCreateOrganizerConversation;

  const EventPublishEvent(
    this.payload, {
    this.shouldCreateOrganizerConversation = false,
  });
}

final class EventSaveDraftEvent extends EventEvent {
  final EventCreatePayload payload;
  final bool shouldCreateOrganizerConversation;
  final String? eventId;

  const EventSaveDraftEvent(
    this.payload, {
    this.shouldCreateOrganizerConversation = false,
    this.eventId,
  });
}

final class EventUpdateEvent extends EventEvent {
  final String eventId;
  final EventCreatePayload payload;

  const EventUpdateEvent(this.eventId, this.payload);
}
