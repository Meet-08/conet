import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageGetConversations {
  final MessageRepository _messageRepository;

  MessageGetConversations({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, List<Conversation>>> call() async {
    return _messageRepository.getConversations();
  }
}
