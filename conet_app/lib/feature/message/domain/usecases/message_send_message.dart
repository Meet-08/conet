import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/repositories/message_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class MessageSendMessage {
  final MessageRepository _messageRepository;

  MessageSendMessage({required MessageRepository messageRepository})
    : _messageRepository = messageRepository;

  Future<Either<AppFailure, Message>> call({
    required String conversationId,
    required String content,
    List<String>? mediaUrls,
    List<PlatformFile>? files,
  }) async {
    return _messageRepository.sendMessage(
      conversationId,
      content,
      mediaUrls: mediaUrls,
      files: files,
    );
  }
}
