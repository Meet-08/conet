import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class MessageUpdateGroup {
  final MessageRepository _messageRepository;

  MessageUpdateGroup({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Conversation>> call({
    required String groupId,
    String? name,
    String? groupImageUrl,
    PlatformFile? groupImageFile,
  }) {
    return _messageRepository.updateGroup(
      groupId: groupId,
      name: name,
      groupImageUrl: groupImageUrl,
      groupImageFile: groupImageFile,
    );
  }
}
