import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageGetMessages {
  final MessageRepository _messageRepository;

  MessageGetMessages({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, List<Message>>> call({
    required String conversationId,
    int limit = 20,
  }) async {
    return _messageRepository.getMessages(conversationId, limit: limit);
  }
}
