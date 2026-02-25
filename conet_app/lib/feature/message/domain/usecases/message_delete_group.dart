import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageDeleteGroup {
  final MessageRepository _messageRepository;

  MessageDeleteGroup({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Unit>> call({required String groupId}) {
    return _messageRepository.deleteGroup(groupId);
  }
}
