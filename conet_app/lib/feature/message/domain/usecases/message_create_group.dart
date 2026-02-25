import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageCreateGroup {
  final MessageRepository _messageRepository;

  MessageCreateGroup({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Conversation>> call({
    required String name,
    required List<String> memberIds,
    String? groupImageUrl,
  }) {
    return _messageRepository.createGroup(
      name: name,
      memberIds: memberIds,
      groupImageUrl: groupImageUrl,
    );
  }
}
