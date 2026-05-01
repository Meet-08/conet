import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessagePromoteGroupMember {
  final MessageRepository _messageRepository;

  MessagePromoteGroupMember({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, GroupMember>> call({
    required String groupId,
    required String userId,
  }) {
    return _messageRepository.promoteGroupMember(
      groupId: groupId,
      userId: userId,
    );
  }
}
