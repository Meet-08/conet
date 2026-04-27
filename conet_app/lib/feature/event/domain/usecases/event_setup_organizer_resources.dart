import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:fpdart/fpdart.dart';

class EventSetupOrganizerResources {
  final EventRepository _repository;

  EventSetupOrganizerResources({required EventRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call({
    required String eventId,
    required List<String> cohostUserIds,
    required bool createEventConversation,
    String? conversationId,
  }) {
    return _repository.setupOrganizerResources(
      eventId: eventId,
      cohostUserIds: cohostUserIds,
      createEventConversation: createEventConversation,
      conversationId: conversationId,
    );
  }
}
