import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/message/data/models/group_member_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MessageDataSource {
  Future<Conversation> createConversation({required String userId});

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    List<String>? mediaUrls,
  });

  Future<MessagePage> getMessages({
    required String conversationId,
    int limit = 20,
    DateTime? before,
  });

  Future<Unit> markAsRead({required String conversationId});

  Future<List<Conversation>> getConversations({String type = 'all'});

  Future<List<User>> searchUsers({required String query, int limit = 3});

  // ─── Group operations ───────────────────────────────────────────────────────

  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
    String? groupImageUrl,
  });

  Future<Conversation> updateGroup({
    required String groupId,
    String? name,
    String? groupImageUrl,
  });

  Future<Unit> deleteGroup({required String groupId});

  Future<List<GroupMemberModel>> getGroupMembers({required String groupId});

  Future<GroupMemberModel> addGroupMember({
    required String groupId,
    required String userId,
  });

  Future<Unit> removeGroupMember({
    required String groupId,
    required String userId,
  });
}
