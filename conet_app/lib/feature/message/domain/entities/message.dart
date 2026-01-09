import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Message extends Equatable {
  final String id;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'sender_id')
  final String senderId;

  final String content;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'is_read')
  final bool isRead;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.isRead = false,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    createdAt,
    isRead,
  ];
}
