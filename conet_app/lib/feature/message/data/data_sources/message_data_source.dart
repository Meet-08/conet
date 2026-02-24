import 'package:conet_app/core/common/entities/user.dart';
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

  Future<List<Conversation>> getConversations();

  Future<List<User>> searchUsers({required String query, int limit = 3});
}
