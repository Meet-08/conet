import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MessageRepository {
  Future<Either<AppFailure, Conversation>> createConversation(String userId);

  Future<Either<AppFailure, Unit>> sendMessage(
    String conversationId,
    String message, {
    List<String>? mediaUrls,
    List<PlatformFile>? files,
  });

  Future<Either<AppFailure, List<Message>>> getMessages(
    String conversationId, {
    int limit = 20,
  });

  Future<Either<AppFailure, Unit>> markAsRead(String conversationId);

  Stream<List<Message>> watchMessages(String conversationId);

  Future<Either<AppFailure, List<Conversation>>> getConversations();

  Future<Either<AppFailure, List<User>>> searchUsers(
    String query, {
    int limit = 3,
  });
}
