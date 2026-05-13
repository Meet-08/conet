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
  final String? content;
  final List<String>? mediaUrls;
  final List<PlatformFile>? files;
  final bool isPost;
  final String? postId;

  MessageSent({
    required this.conversationId,
    this.content,
    this.mediaUrls,
    this.files,
    this.isPost = false,
    this.postId,
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
  final String? description;
  final List<String> userIds;
  final bool onlyAdminAddMembers;
  final bool onlyAdminRemoveMembers;
  final bool onlyAdminEditGroup;
  final bool onlyAdminSendMessages;
  final String? groupImageUrl;
  final PlatformFile? groupImageFile;
  MessageGroupCreated({
    required this.name,
    this.description,
    required this.userIds,
    this.onlyAdminAddMembers = true,
    this.onlyAdminRemoveMembers = true,
    this.onlyAdminEditGroup = true,
    this.onlyAdminSendMessages = true,
    this.groupImageUrl,
    this.groupImageFile,
  });
}

class MessageConversationsRequested extends MessageEvent {
  final String? searchQuery;

  MessageConversationsRequested({this.searchQuery});
}

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
  final String? description;
  final String? groupImageUrl;
  final bool? onlyAdminAddMembers;
  final bool? onlyAdminRemoveMembers;
  final bool? onlyAdminEditGroup;
  final bool? onlyAdminSendMessages;
  final PlatformFile? groupImageFile;
  MessageGroupUpdated({
    required this.groupId,
    this.name,
    this.description,
    this.groupImageUrl,
    this.onlyAdminAddMembers,
    this.onlyAdminRemoveMembers,
    this.onlyAdminEditGroup,
    this.onlyAdminSendMessages,
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

class MessageGroupMemberPromoted extends MessageEvent {
  final String groupId;
  final String userId;
  MessageGroupMemberPromoted({required this.groupId, required this.userId});
}

class MessageGroupMemberDemoted extends MessageEvent {
  final String groupId;
  final String userId;
  MessageGroupMemberDemoted({required this.groupId, required this.userId});
}

class MessageFetchSharedContentRequested extends MessageEvent {
  final String conversationId;
  final String type; // 'media', 'post', 'docs'

  MessageFetchSharedContentRequested({
    required this.conversationId,
    required this.type,
  });
}

class MessageFetchMoreSharedContentRequested extends MessageEvent {
  final String conversationId;
  final String type; // 'media', 'post', 'docs'

  MessageFetchMoreSharedContentRequested({
    required this.conversationId,
    required this.type,
  });
}
