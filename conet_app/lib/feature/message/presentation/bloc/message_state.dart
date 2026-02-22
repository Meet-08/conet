part of 'message_bloc.dart';

enum MessageStatus { initial, loading, success, failure, sending }

class MessageState {
  final List<Message> messages;
  final List<Conversation> conversations;
  final List<User> userSuggestions;
  final MessageStatus status;
  final bool isSearchingUsers;
  final String? userSearchError;
  final String? errorMessage;
  final Conversation? createdConversation;
  final String? currentUserId;

  MessageState({
    this.messages = const [],
    this.conversations = const [],
    this.userSuggestions = const [],
    this.status = MessageStatus.initial,
    this.isSearchingUsers = false,
    this.userSearchError,
    this.errorMessage,
    this.createdConversation,
    this.currentUserId,
  });

  MessageState copyWith({
    List<Message>? messages,
    List<Conversation>? conversations,
    List<User>? userSuggestions,
    MessageStatus? status,
    bool? isSearchingUsers,
    String? userSearchError,
    String? errorMessage,
    Conversation? createdConversation,
    bool clearCreatedConversation = false,
    String? currentUserId,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      userSuggestions: userSuggestions ?? this.userSuggestions,
      status: status ?? this.status,
      isSearchingUsers: isSearchingUsers ?? this.isSearchingUsers,
      userSearchError: userSearchError ?? this.userSearchError,
      errorMessage: errorMessage ?? this.errorMessage,
      createdConversation: clearCreatedConversation
          ? null
          : (createdConversation ?? this.createdConversation),
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }
}
