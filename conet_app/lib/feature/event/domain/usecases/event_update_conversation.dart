import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventUpdateConversation {
  final EventRepository _repository;

  EventUpdateConversation({required EventRepository repository})
      : _repository = repository;

  Future<Either<AppFailure, Event>> call({
    required String eventId,
    required String conversationId,
  }) {
    return _repository.updateEventConversationId(
      eventId: eventId,
      conversationId: conversationId,
    );
  }
}
