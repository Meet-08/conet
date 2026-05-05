import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/data/models/group_member_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message_page.dart';
import 'package:conet_app/main.dart';
import 'package:fpdart/fpdart.dart';

class MessageDataSourceImpl implements MessageDataSource {
  final DioClient _dioClient;

  MessageDataSourceImpl({
    required DioClient dioClient,
    required MessageRealTimeDatasource realTimeDatasource,
  }) : _dioClient = dioClient;

  @override
  Future<Conversation> createConversation({required String userId}) async {
    try {
      final res = await _dioClient.dio.post(
        "/conversations",
        queryParameters: {"other_user": userId},
      );
      if (res.statusCode != 201) {
        throw ServerException("Failed to create conversation");
      }
      final data = res.data as Map<String, dynamic>;
      final conversation = data['conversation'] as Map<String, dynamic>;
      return ConversationModel.fromJson(conversation);
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<MessagePage> getMessages({
    required String conversationId,
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      final res = await _dioClient.dio.get(
        "/conversations/$conversationId/messages",
        queryParameters: {
          "limit": limit,
          if (before != null) "before": before.toIso8601String(),
        },
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to get messages");
      }

      final data = res.data as Map<String, dynamic>;
      final messages = (data['messages'] as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      final nextBeforeRaw = data['next_before'];

      return MessagePage(
        messages: messages.map((e) => MessageModel.fromJson(e)).toList(),
        hasMore: data['has_more'] as bool? ?? false,
        nextBefore: nextBeforeRaw is String
            ? DateTime.parse(nextBeforeRaw)
            : null,
      );
    } catch (e) {
      logger.e("Failed to get messages: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Unit> markAsRead({required String conversationId}) async {
    try {
      final res = await _dioClient.dio.post(
        "/conversations/$conversationId/mark_as_read",
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to mark as read");
      }
      return unit;
    } catch (e) {
      logger.e("Failed to mark as read: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    List<String>? mediaUrls,
  }) async {
    try {
      final data = <String, dynamic>{"content": content};
      if (mediaUrls != null && mediaUrls.isNotEmpty) {
        data['mediaUrls'] = mediaUrls;
      }
      final res = await _dioClient.dio.post(
        "/conversations/$conversationId/messages",
        data: data,
      );
      if (res.statusCode != 201) {
        throw ServerException("Failed to send message");
      }
      return MessageModel.fromJson(res.data['message']);
    } catch (e) {
      logger.e("Failed to send message: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<List<Conversation>> getConversations({
    String type = 'all',
    String? search,
  }) async {
    try {
      final queryParameters = <String, dynamic>{'type': type};
      final normalizedSearch = search?.trim();
      if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
        queryParameters['search'] = normalizedSearch;
      }

      final res = await _dioClient.dio.get(
        "/conversations",
        queryParameters: queryParameters,
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to get conversations");
      }
      final conversations = (res.data as List<dynamic>)
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return conversations;
    } catch (e) {
      logger.e("Failed to get conversations: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<List<User>> searchUsers({required String query, int limit = 3}) async {
    try {
      final res = await _dioClient.dio.get(
        "/conversations/search_users",
        queryParameters: {"query": query, "limit": limit},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to search users");
      }
      final users = (res.data as List<dynamic>)
          .map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList();
      return users;
    } catch (e) {
      logger.e("Failed to search users: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  // ─── Group operations ───────────────────────────────────────────────────────

  @override
  Future<Conversation> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? groupImageUrl,
    bool onlyAdminAddMembers = true,
    bool onlyAdminRemoveMembers = true,
    bool onlyAdminEditGroup = true,
    bool onlyAdminSendMessages = true,
    bool isEvent = false,
  }) async {
    try {
      final body = <String, dynamic>{'name': name, 'memberIds': memberIds};
      if (description != null) {
        body['description'] = description;
      }
      if (groupImageUrl != null) {
        body['groupImageUrl'] = groupImageUrl;
      }
      body['onlyAdminAddMembers'] = onlyAdminAddMembers;
      body['onlyAdminRemoveMembers'] = onlyAdminRemoveMembers;
      body['onlyAdminEditGroup'] = onlyAdminEditGroup;
      body['onlyAdminSendMessages'] = onlyAdminSendMessages;
      body['isEvent'] = isEvent;
      final res = await _dioClient.dio.post("/groups", data: body);
      if (res.statusCode != 201) {
        throw ServerException("Failed to create group");
      }
      final data = res.data as Map<String, dynamic>;
      return ConversationModel.fromJson(data['group'] as Map<String, dynamic>);
    } catch (e) {
      logger.e("Failed to create group: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Conversation> updateGroup({
    required String groupId,
    String? name,
    String? description,
    String? groupImageUrl,
    bool? onlyAdminAddMembers,
    bool? onlyAdminRemoveMembers,
    bool? onlyAdminEditGroup,
    bool? onlyAdminSendMessages,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (groupImageUrl != null) body['groupImageUrl'] = groupImageUrl;
      if (onlyAdminAddMembers != null) {
        body['onlyAdminAddMembers'] = onlyAdminAddMembers;
      }
      if (onlyAdminRemoveMembers != null) {
        body['onlyAdminRemoveMembers'] = onlyAdminRemoveMembers;
      }
      if (onlyAdminEditGroup != null) {
        body['onlyAdminEditGroup'] = onlyAdminEditGroup;
      }
      if (onlyAdminSendMessages != null) {
        body['onlyAdminSendMessages'] = onlyAdminSendMessages;
      }

      final res = await _dioClient.dio.patch("/groups/$groupId", data: body);
      if (res.statusCode != 200) {
        throw ServerException("Failed to update group");
      }
      final data = res.data as Map<String, dynamic>;
      return ConversationModel.fromJson(data['group'] as Map<String, dynamic>);
    } catch (e) {
      logger.e("Failed to update group: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Unit> deleteGroup({required String groupId}) async {
    try {
      final res = await _dioClient.dio.delete("/groups/$groupId");
      if (res.statusCode != 200) {
        throw ServerException("Failed to delete group");
      }
      return unit;
    } catch (e) {
      logger.e("Failed to delete group: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<List<GroupMemberModel>> getGroupMembers({
    required String groupId,
  }) async {
    try {
      final res = await _dioClient.dio.get("/groups/$groupId/members");
      if (res.statusCode != 200) {
        throw ServerException("Failed to get group members");
      }
      return (res.data as List<dynamic>)
          .map((e) => GroupMemberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      logger.e("Failed to get group members: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<GroupMemberModel> addGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        "/groups/$groupId/members",
        data: {'userId': userId},
      );
      if (res.statusCode != 201) {
        throw ServerException("Failed to add group member");
      }
      final data = res.data as Map<String, dynamic>;
      return GroupMemberModel.fromJson(data['member'] as Map<String, dynamic>);
    } catch (e) {
      logger.e("Failed to add group member: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Unit> removeGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final res = await _dioClient.dio.delete(
        "/groups/$groupId/members/$userId",
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to remove group member");
      }
      return unit;
    } catch (e) {
      logger.e("Failed to remove group member: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<GroupMemberModel> promoteGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        "/groups/$groupId/members/$userId/promote",
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to promote group member");
      }
      final data = res.data as Map<String, dynamic>;
      return GroupMemberModel.fromJson(data['member'] as Map<String, dynamic>);
    } catch (e) {
      logger.e("Failed to promote group member: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<GroupMemberModel> demoteGroupMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        "/groups/$groupId/members/$userId/demote",
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to demote group member");
      }
      final data = res.data as Map<String, dynamic>;
      return GroupMemberModel.fromJson(data['member'] as Map<String, dynamic>);
    } catch (e) {
      logger.e("Failed to demote group member: ${e.toString()}");
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
