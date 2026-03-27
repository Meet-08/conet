part of 'event_registration_bloc.dart';

@immutable
sealed class EventRegistrationState {
  const EventRegistrationState();
}

final class EventRegistrationInitial extends EventRegistrationState {}

final class EventRegistrationLoading extends EventRegistrationState {}

final class EventRegistrationTicketLoaded extends EventRegistrationState {
  final EventRegistrationTicket ticket;

  const EventRegistrationTicketLoaded(this.ticket);
}

final class EventRegistrationAttendanceLoading extends EventRegistrationState {}

final class EventRegistrationAttendanceSuccess extends EventRegistrationState {
  final EventAttendanceResult result;

  const EventRegistrationAttendanceSuccess(this.result);
}

final class EventRegistrationFailure extends EventRegistrationState {
  final String message;

  const EventRegistrationFailure(this.message);
}
