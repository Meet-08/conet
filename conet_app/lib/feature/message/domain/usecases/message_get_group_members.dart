import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageGetGroupMembers {
  final MessageRepository _messageRepository;

  MessageGetGroupMembers({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, List<GroupMember>>> call({
    required String groupId,
  }) {
    return _messageRepository.getGroupMembers(groupId);
  }
}
