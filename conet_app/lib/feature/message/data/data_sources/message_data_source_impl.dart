import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
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
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Message>> getMessages({
    required String conversationId,
    int limit = 20,
  }) async {
    try {
      final res = await _dioClient.dio.get(
        "/conversations/$conversationId/messages",
        queryParameters: {"limit": limit},
      );
      if (res.statusCode != 200) {
        throw ServerException("Failed to get messages");
      }
      final messages = res.data as List<Map<String, dynamic>>;
      return messages.map((e) => MessageModel.fromJson(e)).toList();
    } catch (e) {
      logger.e("Failed to get messages: ${e.toString()}");
      throw ServerException(e.toString());
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
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final res = await _dioClient.dio.post(
        "/conversations/$conversationId/messages",
        data: {"content": content},
      );
      if (res.statusCode != 201) {
        throw ServerException("Failed to send message");
      }
      return unit;
    } catch (e) {
      logger.e("Failed to send message: ${e.toString()}");
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Conversation>> getConversations() {
    // TODO: implement getConversations
    throw UnimplementedError();
  }
}
