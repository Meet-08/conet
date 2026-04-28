import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageGetConversations {
  final MessageRepository _messageRepository;

  MessageGetConversations({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, List<Conversation>>> call({
    String type = 'all',
    String? search,
  }) async {
    final normalizedSearch = search?.trim();
    if (normalizedSearch == null || normalizedSearch.isEmpty) {
      return _messageRepository.getConversations(type: type);
    }

    return _messageRepository.getConversations(
      type: type,
      search: normalizedSearch,
    );
  }
}
