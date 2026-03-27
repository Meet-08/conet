import 'package:equatable/equatable.dart';

class EventAttendanceResult extends Equatable {
  final bool success;
  final String message;

  const EventAttendanceResult({required this.success, required this.message});

  @override
  List<Object?> get props => [success, message];
}
