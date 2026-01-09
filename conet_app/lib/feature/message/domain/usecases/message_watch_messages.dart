import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';

class MessageWatchMessages {
  final MessageRepository _messageRepository;

  MessageWatchMessages({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Stream<List<Message>> call(String conversationId) {
    return _messageRepository.watchMessages(conversationId);
  }
}
