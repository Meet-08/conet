import 'package:conet_app/feature/event/domain/entities/event_registration_ticket.dart';

class EventRegistrationTicketModel extends EventRegistrationTicket {
  const EventRegistrationTicketModel({
    required super.eventId,
    required super.userId,
    required super.registrationId,
  });

  factory EventRegistrationTicketModel.fromJson(Map<String, dynamic> json) {
    return EventRegistrationTicketModel(
      eventId: json['event_id'] as String,
      userId: json['user_id'] as String,
      registrationId: json['registration_id'] as String,
    );
  }
}
