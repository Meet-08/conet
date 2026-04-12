part of 'message_bloc.dart';

@immutable
sealed class MessageEvent {}

/// Triggered when the user opens a chat to start listening to real-time messages
class MessageWatchStarted extends MessageEvent {
  final String conversationId;
  MessageWatchStarted(this.conversationId);
}

class MessageWatchStopped extends MessageEvent {
  final String conversationId;
  MessageWatchStopped(this.conversationId);
}

class MessageRealtimeReceived extends MessageEvent {
  final MessageRealtimeEvent realtimeEvent;
  final String conversationId;
  MessageRealtimeReceived(this.realtimeEvent, this.conversationId);
}

class MessageSent extends MessageEvent {
  final String conversationId;
  final String content;
  final List<String>? mediaUrls;
  final List<PlatformFile>? files;

  MessageSent({
    required this.conversationId,
    required this.content,
    this.mediaUrls,
    this.files,
  });
}

class MessageFetchHistoryRequested extends MessageEvent {
  final String conversationId;
  MessageFetchHistoryRequested(this.conversationId);
}

class MessageMarkAsReadRequested extends MessageEvent {
  final String conversationId;
  MessageMarkAsReadRequested(this.conversationId);
}

class MessageConversationCreated extends MessageEvent {
  final String userId;
  MessageConversationCreated(this.userId);
}

class MessageGroupCreated extends MessageEvent {
  final String name;
  final List<String> userIds;
  final String? groupImageUrl;
  final PlatformFile? groupImageFile;
  MessageGroupCreated({
    required this.name,
    required this.userIds,
    this.groupImageUrl,
    this.groupImageFile,
  });
}

class MessageConversationsRequested extends MessageEvent {}

class MessageFilterChanged extends MessageEvent {
  final String filter;
  MessageFilterChanged(this.filter);
}

class MessageUserSearchRequested extends MessageEvent {
  final String query;
  MessageUserSearchRequested(this.query);
}

class MessageUserSearchCleared extends MessageEvent {}

class MessageCreatedConversationHandled extends MessageEvent {}

class MessageConversationRealtimePinged extends MessageEvent {}

// ─── Group management events ──────────────────────────────────────────────────

class MessageGroupUpdated extends MessageEvent {
  final String groupId;
  final String? name;
  final String? groupImageUrl;
  final PlatformFile? groupImageFile;
  MessageGroupUpdated({
    required this.groupId,
    this.name,
    this.groupImageUrl,
    this.groupImageFile,
  });
}

class MessageGroupDeleted extends MessageEvent {
  final String groupId;
  MessageGroupDeleted(this.groupId);
}

class MessageGroupMembersRequested extends MessageEvent {
  final String groupId;
  MessageGroupMembersRequested(this.groupId);
}

class MessageGroupMemberAdded extends MessageEvent {
  final String groupId;
  final String userId;
  MessageGroupMemberAdded({required this.groupId, required this.userId});
}

class MessageGroupMemberRemoved extends MessageEvent {
  final String groupId;
  final String userId;
  MessageGroupMemberRemoved({required this.groupId, required this.userId});
}
