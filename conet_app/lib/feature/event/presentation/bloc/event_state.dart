part of 'event_bloc.dart';

@immutable
sealed class EventState {
  const EventState();
}

final class EventInitial extends EventState {}

final class EventLoading extends EventState {}

final class EventLoaded extends EventState {
  final List<EventListItem> events;
  final String? nextCursor;
  final bool hasMore;

  const EventLoaded({
    required this.events,
    this.nextCursor,
    this.hasMore = false,
  });

  EventLoaded copyWith({
    List<EventListItem>? events,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
  }) {
    return EventLoaded(
      events: events ?? this.events,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

final class EventFailure extends EventState {
  final String message;
  const EventFailure(this.message);
}

final class MyEventsLoading extends EventState {}

final class MyEventsLoaded extends EventState {
  final String type;
  final List<EventListItem> events;
  final String? nextCursor;
  final bool hasMore;
  final int pageSize;

  const MyEventsLoaded({
    required this.type,
    required this.events,
    this.nextCursor,
    this.hasMore = false,
    this.pageSize = 20,
  });

  MyEventsLoaded copyWith({
    String? type,
    List<EventListItem>? events,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    int? pageSize,
  }) {
    return MyEventsLoaded(
      type: type ?? this.type,
      events: events ?? this.events,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

final class MyEventsFailure extends EventState {
  final String message;
  const MyEventsFailure(this.message);
}

final class MyOrganizedEventsLoading extends EventState {}

final class MyOrganizedEventsLoaded extends EventState {
  final String? status;
  final List<EventListItem> events;
  final String? nextCursor;
  final bool hasMore;
  final int pageSize;

  const MyOrganizedEventsLoaded({
    this.status,
    required this.events,
    this.nextCursor,
    this.hasMore = false,
    this.pageSize = 20,
  });

  MyOrganizedEventsLoaded copyWith({
    String? status,
    List<EventListItem>? events,
    String? nextCursor,
    bool clearCursor = false,
    bool? hasMore,
    int? pageSize,
  }) {
    return MyOrganizedEventsLoaded(
      status: status ?? this.status,
      events: events ?? this.events,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

final class MyOrganizedEventsFailure extends EventState {
  final String message;
  const MyOrganizedEventsFailure(this.message);
}

final class EventDetailLoading extends EventState {}

final class EventDetailLoaded extends EventState {
  final Event event;

  const EventDetailLoaded(this.event);
}

final class EventDetailFailure extends EventState {
  final String message;

  const EventDetailFailure(this.message);
}

final class EventRegistrationLoading extends EventState {}

final class EventRegistrationSuccess extends EventState {
  final Event event;

  const EventRegistrationSuccess(this.event);
}

final class EventRegistrationFailure extends EventState {
  final String message;

  const EventRegistrationFailure(this.message);
}

// ── Create / Draft states ────────────────────────────────────────────────────

final class EventCreateLoading extends EventState {}

final class EventCreateSuccess extends EventState {
  final Event event;
  final bool isDraft;
  const EventCreateSuccess({required this.event, required this.isDraft});
}

final class EventCreateFailure extends EventState {
  final String message;
  const EventCreateFailure(this.message);
}
