import 'package:equatable/equatable.dart';

class EventRegistrationTrend extends Equatable {
  final int totalRegistrations;
  final List<EventRegistrationTrendPoint> points;

  const EventRegistrationTrend({
    required this.totalRegistrations,
    required this.points,
  });

  @override
  List<Object?> get props => [totalRegistrations, points];
}

class EventRegistrationTrendPoint extends Equatable {
  final DateTime date;
  final int count;

  const EventRegistrationTrendPoint({required this.date, required this.count});

  @override
  List<Object?> get props => [date, count];
}
