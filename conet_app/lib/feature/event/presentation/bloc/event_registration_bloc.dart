import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_info.dart';
import 'package:conet_app/feature/event/domain/usecases/event_mark_attendance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'event_registration_event.dart';
part 'event_registration_state.dart';

class EventRegistrationBloc
    extends Bloc<EventRegistrationEvent, EventRegistrationState> {
  final EventGetRegistrationInfo _getRegistrationInfo;
  final EventMarkAttendance _markAttendance;

  EventRegistrationBloc({
    required EventGetRegistrationInfo getRegistrationInfo,
    required EventMarkAttendance markAttendance,
  }) : _getRegistrationInfo = getRegistrationInfo,
       _markAttendance = markAttendance,
       super(EventRegistrationInitial()) {
    on<EventRegistrationFetchTicketEvent>(_onFetchTicket);
    on<EventRegistrationMarkAttendanceEvent>(_onMarkAttendance);
  }

  Future<void> _onFetchTicket(
    EventRegistrationFetchTicketEvent event,
    Emitter<EventRegistrationState> emit,
  ) async {
    emit(EventRegistrationLoading());

    final result = await _getRegistrationInfo(event.eventId);
    result.fold(
      (failure) => emit(EventRegistrationFailure(failure.message)),
      (ticket) => emit(EventRegistrationTicketLoaded(ticket)),
    );
  }

  Future<void> _onMarkAttendance(
    EventRegistrationMarkAttendanceEvent event,
    Emitter<EventRegistrationState> emit,
  ) async {
    emit(EventRegistrationAttendanceLoading());

    final result = await _markAttendance(
      eventId: event.eventId,
      userId: event.userId,
      registrationId: event.registrationId,
    );

    result.fold(
      (failure) => emit(EventRegistrationFailure(failure.message)),
      (attendance) => emit(EventRegistrationAttendanceSuccess(attendance)),
    );
  }
}
