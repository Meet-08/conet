import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class EventRegistrationTicket extends Equatable {
  @JsonKey(name: 'event_id')
  final String eventId;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'registration_id')
  final String registrationId;

  const EventRegistrationTicket({
    required this.eventId,
    required this.userId,
    required this.registrationId,
  });

  String get ticketId => registrationId;

  @override
  List<Object?> get props => [eventId, userId, registrationId];
}
