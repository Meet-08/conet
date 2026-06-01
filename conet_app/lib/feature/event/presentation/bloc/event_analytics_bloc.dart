import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_attendees.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_college.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_course.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_trend_by_date.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'event_analytics_event.dart';
part 'event_analytics_state.dart';

class EventAnalyticsBloc
    extends Bloc<EventAnalyticsEvent, EventAnalyticsState> {
  final EventGetById _getById;
  final EventGetAttendees _getAttendees;
  final EventGetRegistrationTrendByDate _getTrendByDate;
  final EventGetRegistrationCountByCollege _getCollegeCounts;
  final EventGetRegistrationCountByCourse _getCourseCounts;

  EventAnalyticsBloc({
    required EventGetById getById,
    required EventGetAttendees getAttendees,
    required EventGetRegistrationTrendByDate getTrendByDate,
    required EventGetRegistrationCountByCollege getCollegeCounts,
    required EventGetRegistrationCountByCourse getCourseCounts,
  }) : _getById = getById,
       _getAttendees = getAttendees,
       _getTrendByDate = getTrendByDate,
       _getCollegeCounts = getCollegeCounts,
       _getCourseCounts = getCourseCounts,
       super(EventAnalyticsInitial()) {
    on<EventAnalyticsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    EventAnalyticsLoadRequested event,
    Emitter<EventAnalyticsState> emit,
  ) async {
    emit(EventAnalyticsLoading());

    final eventFuture = _getById(event.eventId);
    final attendeesFuture = _getAttendees(
      eventId: event.eventId,
      status: 'all',
    );
    final collegesFuture = _getCollegeCounts(event.eventId);
    final coursesFuture = _getCourseCounts(event.eventId);

    final eventResult = await eventFuture;
    final attendeesResult = await attendeesFuture;
    final collegesResult = await collegesFuture;
    final coursesResult = await coursesFuture;

    Event? loadedEvent;
    String? failureMessage;
    eventResult.fold(
      (failure) => failureMessage = failure.message,
      (data) => loadedEvent = data,
    );
    if (failureMessage != null) {
      emit(EventAnalyticsFailure(failureMessage!));
      return;
    }
    if (loadedEvent == null) {
      emit(const EventAnalyticsFailure('Unable to load event details'));
      return;
    }
    final Event resolvedEvent = loadedEvent!;

    EventAttendees? loadedAttendees;
    attendeesResult.fold(
      (failure) => failureMessage = failure.message,
      (data) => loadedAttendees = data,
    );
    if (failureMessage != null) {
      emit(EventAnalyticsFailure(failureMessage!));
      return;
    }
    if (loadedAttendees == null) {
      emit(const EventAnalyticsFailure('Unable to load attendee summary'));
      return;
    }
    final EventAttendees resolvedAttendees = loadedAttendees!;

    final now = DateTime.now();
    final eventDate = DateTime(
      resolvedEvent.startDate.year,
      resolvedEvent.startDate.month,
      resolvedEvent.startDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final trendEndDate = eventDate.isBefore(today) ? eventDate : today;
    final createdAt = resolvedEvent.createdAt;
    final trendStartDate = createdAt != null
        ? DateTime(createdAt.year, createdAt.month, createdAt.day)
        : trendEndDate.subtract(const Duration(days: 30));

    var trendResult = await _getTrendByDate(
      eventId: event.eventId,
      from: trendStartDate,
      to: trendEndDate,
    );

    EventRegistrationTrend? loadedTrend;
    trendResult.fold(
      (failure) => failureMessage = failure.message,
      (data) => loadedTrend = data,
    );
    if (failureMessage != null) {
      emit(EventAnalyticsFailure(failureMessage!));
      return;
    }

    if ((loadedTrend?.points.isEmpty ?? true) &&
        resolvedAttendees.summary.registered > 0) {
      trendResult = await _getTrendByDate(
        eventId: event.eventId,
        from: trendStartDate,
        to: trendEndDate,
      );
      trendResult.fold(
        (failure) => failureMessage = failure.message,
        (data) => loadedTrend = data,
      );
      if (failureMessage != null) {
        emit(EventAnalyticsFailure(failureMessage!));
        return;
      }
    }

    if (loadedTrend == null) {
      emit(const EventAnalyticsFailure('Unable to load registration trend'));
      return;
    }
    final EventRegistrationTrend resolvedTrend = loadedTrend!;

    List<EventRegistrationCount>? loadedCollegeCounts;
    collegesResult.fold(
      (failure) => failureMessage = failure.message,
      (data) => loadedCollegeCounts = data,
    );
    if (failureMessage != null) {
      emit(EventAnalyticsFailure(failureMessage!));
      return;
    }
    if (loadedCollegeCounts == null) {
      emit(const EventAnalyticsFailure('Unable to load college counts'));
      return;
    }
    final List<EventRegistrationCount> resolvedCollegeCounts =
        loadedCollegeCounts!;

    List<EventRegistrationCount>? loadedCourseCounts;
    coursesResult.fold(
      (failure) => failureMessage = failure.message,
      (data) => loadedCourseCounts = data,
    );
    if (failureMessage != null) {
      emit(EventAnalyticsFailure(failureMessage!));
      return;
    }
    if (loadedCourseCounts == null) {
      emit(const EventAnalyticsFailure('Unable to load branch counts'));
      return;
    }
    final List<EventRegistrationCount> resolvedCourseCounts =
        loadedCourseCounts!;

    emit(
      EventAnalyticsLoaded(
        event: resolvedEvent,
        attendees: resolvedAttendees,
        trend: resolvedTrend,
        collegeCounts: resolvedCollegeCounts,
        courseCounts: resolvedCourseCounts,
      ),
    );
  }
}
