import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageRemoveGroupMember {
  final MessageRepository _messageRepository;

  MessageRemoveGroupMember({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Unit>> call({
    required String groupId,
    required String userId,
  }) {
    return _messageRepository.removeGroupMember(
      groupId: groupId,
      userId: userId,
    );
  }
}
