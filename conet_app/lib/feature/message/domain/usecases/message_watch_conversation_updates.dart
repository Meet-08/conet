import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';

class MessageWatchConversationUpdates {
  final MessageRepository _messageRepository;

  MessageWatchConversationUpdates({
    required MessageRepository messageRepository,
  }) : _messageRepository = messageRepository;

  Stream<void> call() {
    return _messageRepository.watchConversationUpdates();
  }
}
