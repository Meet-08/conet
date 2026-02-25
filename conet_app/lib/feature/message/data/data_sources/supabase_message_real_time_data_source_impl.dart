import 'dart:async';

import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/message_realtime_event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMessageRealTimeDataSourceImpl
    implements MessageRealTimeDatasource {
  final SupabaseClient _supabaseClient;

  SupabaseMessageRealTimeDataSourceImpl({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  @override
  Stream<MessageRealtimeEvent> watchMessages(String conversationId) {
    final controller = StreamController<MessageRealtimeEvent>();

    final channel = _supabaseClient
        .channel('public:messages_$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record['id'] == null) return;
            if (!controller.isClosed) {
              final message = MessageModel.fromJson(record);
              controller.add(
                MessageRealtimeEvent(
                  type: MessageRealtimeEventType.inserted,
                  conversationId: conversationId,
                  messageId: message.id,
                  message: message,
                ),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record['id'] == null) return;
            if (!controller.isClosed) {
              final message = MessageModel.fromJson(record);
              controller.add(
                MessageRealtimeEvent(
                  type: MessageRealtimeEventType.updated,
                  conversationId: conversationId,
                  messageId: message.id,
                  message: message,
                ),
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.delete,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final record = payload.oldRecord;
            final messageId = record['id'] as String?;
            if (messageId == null) return;

            if (!controller.isClosed) {
              controller.add(
                MessageRealtimeEvent(
                  type: MessageRealtimeEventType.deleted,
                  conversationId: conversationId,
                  messageId: messageId,
                ),
              );
            }
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      _supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }

  @override
  Stream<void> watchConversationUpdates() {
    final controller = StreamController<void>();

    final channel = _supabaseClient.channel('public:messages_global');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(null);
            }
          },
        );

    channel.subscribe();

    controller.onCancel = () {
      _supabaseClient.removeChannel(channel);
      controller.close();
    };

    return controller.stream;
  }
}
