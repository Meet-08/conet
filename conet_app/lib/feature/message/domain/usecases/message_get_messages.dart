import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageGetMessages {
  final MessageRepository _messageRepository;

  MessageGetMessages({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, MessagePage>> call({
    required String conversationId,
    int limit = 20,
    DateTime? before,
  }) async {
    return _messageRepository.getMessages(
      conversationId,
      limit: limit,
      before: before,
    );
  }
}
