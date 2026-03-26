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

final class EventFetchByIdEvent extends EventEvent {
  final String eventId;

  const EventFetchByIdEvent(this.eventId);
}

final class EventRegisterEvent extends EventEvent {
  final String eventId;

  const EventRegisterEvent(this.eventId);
}

final class EventPublishEvent extends EventEvent {
  final EventCreatePayload payload;
  const EventPublishEvent(this.payload);
}

final class EventSaveDraftEvent extends EventEvent {
  final EventCreatePayload payload;
  const EventSaveDraftEvent(this.payload);
}
