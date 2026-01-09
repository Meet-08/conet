import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageSendMessage {
  final MessageRepository _messageRepository;

  MessageSendMessage({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Unit>> call({
    required String conversationId,
    required String content,
  }) async {
    return _messageRepository.sendMessage(conversationId, content);
  }
}
