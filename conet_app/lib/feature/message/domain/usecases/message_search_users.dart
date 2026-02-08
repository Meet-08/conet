import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:fpdart/fpdart.dart';

class MessageSearchUsers {
  final MessageRepository _messageRepository;

  MessageSearchUsers({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, List<User>>> call({
    required String query,
    int limit = 3,
  }) {
    return _messageRepository.searchUsers(query, limit: limit);
  }
}
