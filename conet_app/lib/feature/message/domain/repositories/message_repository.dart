import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MessageRepository {
  Future<Either<AppFailure, Conversation>> createConversation(String userId);

  Future<Either<AppFailure, Message>> sendMessage(
    String conversationId,
    String message, {
    List<String>? mediaUrls,
    List<PlatformFile>? files,
  });

  Future<Either<AppFailure, MessagePage>> getMessages(
    String conversationId, {
    int limit = 20,
    DateTime? before,
  });

  Future<Either<AppFailure, Unit>> markAsRead(String conversationId);

  Stream<MessageRealtimeEvent> watchMessages(String conversationId);
  Stream<void> watchConversationUpdates();

  Future<Either<AppFailure, List<Conversation>>> getConversations({
    String type = 'all',
    String? search,
  });

  Future<Either<AppFailure, List<User>>> searchUsers(
    String query, {
    int limit = 3,
  });

  // ─── Group operations ───────────────────────────────────────────────────────

  Future<Either<AppFailure, Conversation>> createGroup({
    required String name,
    required List<String> memberIds,
    PlatformFile? groupImageFile,
  });

  Future<Either<AppFailure, Conversation>> updateGroup({
    required String groupId,
    String? name,
    String? groupImageUrl,
    PlatformFile? groupImageFile,
  });

  Future<Either<AppFailure, Unit>> deleteGroup(String groupId);

  Future<Either<AppFailure, List<GroupMember>>> getGroupMembers(String groupId);

  Future<Either<AppFailure, GroupMember>> addGroupMember({
    required String groupId,
    required String userId,
  });

  Future<Either<AppFailure, Unit>> removeGroupMember({
    required String groupId,
    required String userId,
  });
}
