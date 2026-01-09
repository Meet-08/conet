part of 'message_bloc.dart';

enum MessageStatus { initial, loading, success, failure, sending }

class MessageState {
  final List<Message> messages;
  final List<Conversation> conversations;
  final MessageStatus status;
  final String? errorMessage;

  MessageState({
    this.messages = const [],
    this.conversations = const [],
    this.status = MessageStatus.initial,
    this.errorMessage,
  });

  MessageState copyWith({
    List<Message>? messages,
    List<Conversation>? conversations,
    MessageStatus? status,
    String? errorMessage,
  }) {
    return MessageState(
      messages: messages ?? this.messages,
      conversations: conversations ?? this.conversations,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
