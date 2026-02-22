import 'dart:async';

import 'package:conet_app/feature/message/data/data_sources/message_real_time_datasource.dart';
import 'package:conet_app/feature/message/data/models/message_model.dart';
import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMessageRealTimeDataSourceImpl
    implements MessageRealTimeDatasource {
  final SupabaseClient _supabaseClient;

  SupabaseMessageRealTimeDataSourceImpl({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _supabaseClient
        .from("messages")
        .stream(primaryKey: ['id'])
        .eq("conversation_id", conversationId)
        .order("created_at", ascending: false)
        .map((event) {
          return event.map((map) => MessageModel.fromJson(map)).toList();
        });
  }

  @override
  Stream<void> watchConversationUpdates() {
    final controller = StreamController<void>();

    final channel = _supabaseClient
        .channel('public:messages_global')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
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
