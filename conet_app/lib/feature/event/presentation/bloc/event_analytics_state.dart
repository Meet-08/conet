part of 'event_analytics_bloc.dart';

sealed class EventAnalyticsState extends Equatable {
  const EventAnalyticsState();

  @override
  List<Object?> get props => [];
}

class EventAnalyticsInitial extends EventAnalyticsState {}

class EventAnalyticsLoading extends EventAnalyticsState {}

class EventAnalyticsLoaded extends EventAnalyticsState {
  final Event event;
  final EventAttendees attendees;
  final EventRegistrationTrend trend;
  final List<EventRegistrationCount> collegeCounts;
  final List<EventRegistrationCount> courseCounts;

  const EventAnalyticsLoaded({
    required this.event,
    required this.attendees,
    required this.trend,
    required this.collegeCounts,
    required this.courseCounts,
  });

  @override
  List<Object?> get props => [
    event,
    attendees,
    trend,
    collegeCounts,
    courseCounts,
  ];
}

class EventAnalyticsFailure extends EventAnalyticsState {
  final String message;

  const EventAnalyticsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
