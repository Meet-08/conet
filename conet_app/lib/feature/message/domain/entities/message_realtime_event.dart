import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:equatable/equatable.dart';

enum MessageRealtimeEventType { inserted, updated, deleted }

class MessageRealtimeEvent extends Equatable {
  final MessageRealtimeEventType type;
  final String conversationId;
  final String messageId;
  final Message? message;

  const MessageRealtimeEvent({
    required this.type,
    required this.conversationId,
    required this.messageId,
    this.message,
  });

  @override
  List<Object?> get props => [type, conversationId, messageId, message];
}
