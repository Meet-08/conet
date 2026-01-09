import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageMarkAsRead {
  final MessageRepository _messageRepository;

  MessageMarkAsRead({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Unit>> call({
    required String conversationId,
  }) async {
    return _messageRepository.markAsRead(conversationId);
  }
}
