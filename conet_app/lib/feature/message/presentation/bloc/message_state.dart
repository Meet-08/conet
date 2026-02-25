part of 'message_bloc.dart';

enum MessageStatus { initial, loading, success, failure, sending }

class MessageState {
  final List<Message> messages;
  final List<Conversation> conversations;
  final List<User> userSuggestions;
  final List<GroupMember> groupMembers;
  final MessageStatus conversationStatus;
  final MessageStatus messageStatus;
  final bool isSearchingUsers;
  final String? userSearchError;
  final String? errorMessage;
  final Conversation? createdConversation;
  final String? currentUserId;
  final bool isFetchingHistory;
  final bool hasMoreHistory;
  final DateTime? nextBeforeCursor;
  final String? activeConversationId;
  final DateTime? lastConversationRealtimeAt;
  final String conversationFilter; // 'all', 'direct', 'group'

  MessageState({
    this.messages = const [],
    this.conversations = const [],
    this.userSuggestions = const [],
    this.groupMembers = const [],
    this.conversationStatus = MessageStatus.initial,
    this.messageStatus = MessageStatus.initial,
    this.isSearchingUsers = false,
    this.userSearchError,
    this.errorMessage,
    this.createdConversation,
    this.currentUserId,
    this.isFetchingHistory = false,
    this.hasMoreHistory = true,
    this.nextBeforeCursor,
    this.activeConversationId,
    this.lastConversationRealtimeAt,
    this.conversationFilter = 'all',
  });

  MessageState copyWith({
    List<Message>? messages,
    List<Conversation>? conversations,
    List<User>? userSuggestions,
    List<GroupMember>? groupMembers,
    MessageStatus? conversationStatus,
    MessageStatus? messageStatus,
    bool? isSearchingUsers,
    String? userSearchError,
    String? errorMessage,
    Conversation? createdConversation,
    bool clearCreatedConversation = false,
    String? currentUserId,
    bool? isFetchingHistory,
    bool? hasMoreHistory,
    DateTime? nextBeforeCursor,
    String? activeConversationId,
    DateTime? lastConversationRealtimeAt,
    bool clearNextBeforeCursor = false,
    String? conversationFilter,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      userSuggestions: userSuggestions ?? this.userSuggestions,
      groupMembers: groupMembers ?? this.groupMembers,
      conversationStatus: conversationStatus ?? this.conversationStatus,
      messageStatus: messageStatus ?? this.messageStatus,
      isSearchingUsers: isSearchingUsers ?? this.isSearchingUsers,
      userSearchError: userSearchError ?? this.userSearchError,
      errorMessage: errorMessage ?? this.errorMessage,
      createdConversation: clearCreatedConversation
          ? null
          : (createdConversation ?? this.createdConversation),
      currentUserId: currentUserId ?? this.currentUserId,
      isFetchingHistory: isFetchingHistory ?? this.isFetchingHistory,
      hasMoreHistory: hasMoreHistory ?? this.hasMoreHistory,
      nextBeforeCursor: clearNextBeforeCursor
          ? null
          : (nextBeforeCursor ?? this.nextBeforeCursor),
      activeConversationId: activeConversationId ?? this.activeConversationId,
      lastConversationRealtimeAt:
          lastConversationRealtimeAt ?? this.lastConversationRealtimeAt,
      conversationFilter: conversationFilter ?? this.conversationFilter,
    );
  }
}
