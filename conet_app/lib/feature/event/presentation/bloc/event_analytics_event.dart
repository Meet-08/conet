part of 'event_analytics_bloc.dart';

sealed class EventAnalyticsEvent extends Equatable {
  const EventAnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class EventAnalyticsLoadRequested extends EventAnalyticsEvent {
  final String eventId;

  const EventAnalyticsLoadRequested({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}
