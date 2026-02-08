part of 'message_bloc.dart';

@immutable
sealed class MessageEvent {}

/// Triggered when the user opens a chat to start listening to real-time messages
class MessageWatchStarted extends MessageEvent {
  final String conversationId;
  MessageWatchStarted(this.conversationId);
}

class MessageListUpdated extends MessageEvent {
  final List<Message> messages;
  MessageListUpdated(this.messages);
}

class MessageSent extends MessageEvent {
  final String conversationId;
  final String content;
  MessageSent({required this.conversationId, required this.content});
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

class MessageConversationsRequested extends MessageEvent {}

class MessageUserSearchRequested extends MessageEvent {
  final String query;
  MessageUserSearchRequested(this.query);
}

class MessageUserSearchCleared extends MessageEvent {}
