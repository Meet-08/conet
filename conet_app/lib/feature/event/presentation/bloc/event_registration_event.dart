part of 'event_registration_bloc.dart';

@immutable
sealed class EventRegistrationEvent {
  const EventRegistrationEvent();
}

final class EventRegistrationFetchTicketEvent extends EventRegistrationEvent {
  final String eventId;

  const EventRegistrationFetchTicketEvent(this.eventId);
}

final class EventRegistrationMarkAttendanceEvent
    extends EventRegistrationEvent {
  final String eventId;
  final String userId;
  final String registrationId;

  const EventRegistrationMarkAttendanceEvent({
    required this.eventId,
    required this.userId,
    required this.registrationId,
  });
}
