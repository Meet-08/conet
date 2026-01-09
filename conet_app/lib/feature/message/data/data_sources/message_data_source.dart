import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MessageDataSource {
  Future<Conversation> createConversation({required String userId});

  Future<Unit> sendMessage({
    required String conversationId,
    required String content,
  });

  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 20,
  });

  Future<Unit> markAsRead({required String conversationId});

  Future<List<Conversation>> getConversations();
}
