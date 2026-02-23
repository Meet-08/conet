import 'dart:async';

import 'package:conet_app/core/common/data_sources/presence_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase Realtime Presence implementation of [PresenceDataSource].
class SupabasePresenceDataSource implements PresenceDataSource {
  final SupabaseClient _supabaseClient;

  RealtimeChannel? _channel;
  StreamController<Set<String>>? _controller;

  SupabasePresenceDataSource({required SupabaseClient supabaseClient})
    : _supabaseClient = supabaseClient;

  @override
  Stream<Set<String>> watchOnlineUsers(String userId) {
    _controller = StreamController<Set<String>>.broadcast();
    final onlineUsers = <String>{};

    _channel = _supabaseClient.channel(
      'online-users',
      opts: const RealtimeChannelConfig(self: true),
    );

    _channel!
        .onPresenceSync((payload) {
          onlineUsers.clear();
          final presences = _channel!.presenceState();
          for (final state in presences) {
            for (final presence in state.presences) {
              final uid = presence.payload['user_id'] as String?;
              if (uid != null) onlineUsers.add(uid);
            }
          }
          if (!_controller!.isClosed) {
            _controller!.add(Set<String>.from(onlineUsers));
          }
        })
        .onPresenceJoin((payload) {
          for (final p in payload.newPresences) {
            final uid = p.payload['user_id'] as String?;
            if (uid != null) onlineUsers.add(uid);
          }
          if (!_controller!.isClosed) {
            _controller!.add(Set<String>.from(onlineUsers));
          }
        })
        .onPresenceLeave((payload) {
          for (final p in payload.leftPresences) {
            final uid = p.payload['user_id'] as String?;
            if (uid != null) onlineUsers.remove(uid);
          }
          if (!_controller!.isClosed) {
            _controller!.add(Set<String>.from(onlineUsers));
          }
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await _channel!.track({'user_id': userId});
          }
        });

    return _controller!.stream;
  }

  @override
  Future<void> dispose() async {
    if (_channel != null) {
      await _channel!.untrack();
      await _supabaseClient.removeChannel(_channel!);
      _channel = null;
    }
    if (_controller != null && !_controller!.isClosed) {
      await _controller!.close();
      _controller = null;
    }
  }
}
