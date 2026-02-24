import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';

class MessageWatchMessages {
  final MessageRepository _messageRepository;

  MessageWatchMessages({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Stream<MessageRealtimeEvent> call(String conversationId) {
    return _messageRepository.watchMessages(conversationId);
  }
}
