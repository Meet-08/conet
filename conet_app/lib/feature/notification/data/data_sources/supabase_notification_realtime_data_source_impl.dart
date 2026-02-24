import 'dart:async';

import 'package:conet_app/feature/notification/data/data_sources/notification_realtime_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseNotificationRealtimeDataSourceImpl
    implements NotificationRealtimeDataSource {
  final SupabaseClient _supabaseClient;

  SupabaseNotificationRealtimeDataSourceImpl({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  @override
  Stream<Map<String, dynamic>> watchNewNotifications(String userId) {
    final controller = StreamController<Map<String, dynamic>>();

    final channel = _supabaseClient
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: userId,
          ),
          callback: (payload) {
            if (!controller.isClosed) {
              controller.add(payload.newRecord);
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
