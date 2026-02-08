import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/message/data/data_sources/message_data_source.dart';
import 'package:conet_app/feature/message/data/models/conversation_model.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/main.dart';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class SupabaseMessageDataSourceImpl implements MessageDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseMessageDataSourceImpl(this._supabaseClient);

  @override
  Future<Conversation> createConversation({required String userId}) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null) {
        throw ServerException('Not authenticated');
      }
      final currentUserId = currentUser.id;

      final resolvedUserId = await _resolveUserId(userId);
      if (resolvedUserId == currentUserId) {
        throw ServerException('Cannot create conversation with yourself');
      }
      final pair = _normalizeConversationPair(currentUserId, resolvedUserId);
      logger.d(
        'Create conversation: currentUserId=$currentUserId, resolvedUserId=$resolvedUserId, userOne=${pair.$1}, userTwo=${pair.$2}',
      );

      // Check if conversation already exists
      final existingConversation = await _supabaseClient
          .from('conversations')
          .select()
          .eq('user_one', pair.$1)
          .eq('user_two', pair.$2)
          .maybeSingle();

      Map<String, dynamic> conversationData;

      if (existingConversation != null) {
        conversationData = existingConversation;
      } else {
        // Create new conversation
        conversationData = await _supabaseClient
            .from('conversations')
            .insert({'user_one': pair.$1, 'user_two': pair.$2})
            .select()
            .single();
      }

      // Fetch the other user's details
      final otherUserData = await _supabaseClient
          .from('users')
          .select()
          .eq('id', resolvedUserId)
          .single();

      final otherUser = User.fromJson(otherUserData);

      return ConversationModel(
        id: conversationData['id'],
        otherUser: otherUser,
      );
    } catch (e) {
      if (e is PostgrestException && e.code == '23514') {
        try {
          final currentUserId = _supabaseClient.auth.currentUser?.id;
          if (currentUserId == null) {
            throw ServerException('Not authenticated');
          }
          final resolvedUserId = await _resolveUserId(userId);
          final pair = _normalizeConversationPair(
            currentUserId,
            resolvedUserId,
          );

          final existingConversation = await _supabaseClient
              .from('conversations')
              .select()
              .eq('user_one', pair.$1)
              .eq('user_two', pair.$2)
              .maybeSingle();

          if (existingConversation != null) {
            final otherUserData = await _supabaseClient
                .from('users')
                .select()
                .eq('id', resolvedUserId)
                .single();

            return ConversationModel(
              id: existingConversation['id'],
              otherUser: User.fromJson(otherUserData),
            );
          }
        } catch (_) {
          // fall through to error below
        }
      }

      logger.e('Create conversation failed: ${e.toString()}');
      throw ServerException(e.toString());
    }
  }

  Future<String> _resolveUserId(String identifier) async {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );

    if (uuidRegex.hasMatch(identifier)) {
      return identifier;
    }

    final user = await _supabaseClient
        .from('users')
        .select('id')
        .or('username.eq.$identifier,email.eq.$identifier')
        .maybeSingle();

    if (user == null || user['id'] == null) {
      throw ServerException('User not found');
    }

    return user['id'] as String;
  }

  (String, String) _normalizeConversationPair(
    String currentUserId,
    String otherUserId,
  ) {
    if (currentUserId.compareTo(otherUserId) <= 0) {
      return (currentUserId, otherUserId);
    }
    return (otherUserId, currentUserId);
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
          .select(
            'id, user_one, user_two, user_one_profile:users!user_one(*), user_two_profile:users!user_two(*)',
          )
          .or('user_one.eq.$currentUserId,user_two.eq.$currentUserId');

      logger.d('Get conversations: currentUserId=$currentUserId');
      logger.d('Get conversations raw: $response');

      final conversations = <Conversation>[];

      for (final data in response) {
        final userOneId = data['user_one']?.toString();
        final userTwoId = data['user_two']?.toString();

        if (userOneId == null || userTwoId == null) {
          continue;
        }

        final otherUserId = userOneId == currentUserId ? userTwoId : userOneId;

        final otherUserData = userOneId == currentUserId
            ? data['user_two_profile']
            : data['user_one_profile'];

        User otherUser;

        if (otherUserData is Map<String, dynamic>) {
          otherUser = User.fromJson(otherUserData);
        } else {
          final fetched = await _supabaseClient
              .from('users')
              .select()
              .eq('id', otherUserId)
              .maybeSingle();

          if (fetched == null) {
            continue;
          }

          otherUser = User.fromJson(fetched);
        }

        final conversationId = data['id']?.toString();
        if (conversationId == null || conversationId.isEmpty) {
          continue;
        }

        conversations.add(
          ConversationModel(id: conversationId, otherUser: otherUser),
        );
      }
      logger.d('Get conversations mapped: ${conversations.length}');
      return conversations;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<User>> searchUsers({required String query, int limit = 3}) async {
    try {
      final currentUserId = _supabaseClient.auth.currentUser?.id;
      final orFilter = currentUserId == null
          ? 'username.ilike.%$query%,email.ilike.%$query%'
          : 'and(username.ilike.%$query%,id.neq.$currentUserId),and(email.ilike.%$query%,id.neq.$currentUserId)';

      final response = await _supabaseClient
          .from('users')
          .select(
            'id, username, email, first_name, last_name, profile_pic_url, user_role, is_verified',
          )
          .or(orFilter)
          .limit(limit)
          .order('username', ascending: true);
      return response.map((row) => User.fromJson(row)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
