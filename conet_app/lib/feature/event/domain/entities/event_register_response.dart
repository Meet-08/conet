import 'package:conet_app/feature/event/domain/entities/event.dart';

class EventRegisterResponse {
  final Event event;
  final String registrationId;

  const EventRegisterResponse({
    required this.event,
    required this.registrationId,
  });
}
