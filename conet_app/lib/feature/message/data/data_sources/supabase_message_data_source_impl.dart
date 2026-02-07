import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class SupabaseMessageDataSourceImpl implements MessageDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseMessageDataSourceImpl(this._supabaseClient);

  @override
  Future<Conversation> createConversation({required String userId}) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser!.id;

      // Check if conversation already exists
      final existingConversation = await _supabaseClient
          .from('conversations')
          .select()
          .or(
            'and(user_one.eq.$currentUserId,user_two.eq.$userId),and(user_one.eq.$userId,user_two.eq.$currentUserId)',
          )
          .maybeSingle();

      Map<String, dynamic> conversationData;

      if (existingConversation != null) {
        conversationData = existingConversation;
      } else {
        // Create new conversation
        conversationData = await _supabaseClient
            .from('conversations')
            .insert({'user_one': currentUserId, 'user_two': userId})
            .select()
            .single();
      }

      // Fetch the other user's details
      final otherUserData = await _supabaseClient
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final otherUser = User.fromJson(otherUserData);

      return ConversationModel(
        id: conversationData['id'],
        otherUser: otherUser,
      );
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
      final response = await _supabaseClient
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((message) => MessageModel.fromJson(message)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> markAsRead({required String conversationId}) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser!.id;

      await _supabaseClient
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', currentUserId); // Only mark messages sent by others

      return unit;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser!.id;

      await _supabaseClient.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': currentUserId,
        'content': content,
      });

      return unit;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Conversation>> getConversations() async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser!.id;

      final response = await _supabaseClient
          .from('conversations')
          .select('*, user_one:users!user_one(*), user_two:users!user_two(*)')
          .or('user_one.eq.$currentUserId,user_two.eq.$currentUserId');

      return response.map((data) {
        // Determine which user object is the "other" user
        final userOneId = data['user_one']['id'];
        final otherUserData = userOneId == currentUserId
            ? data['user_two']
            : data['user_one'];

        return ConversationModel(
          id: data['id'],
          otherUser: User.fromJson(otherUserData),
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
