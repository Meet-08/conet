import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

enum MessageDeliveryStatus { pending, sent, error }

class Message extends Equatable {
  final String id;

  @JsonKey(name: 'conversation_id')
  final String conversationId;

  @JsonKey(name: 'sender_id')
  final String senderId;

  final String? content;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'is_read')
  final bool isRead;

  @JsonKey(name: 'media_urls')
  final List<String> mediaUrls;

  final MessageDeliveryStatus status;

  @JsonKey(name: 'is_post')
  final bool isPost;

  @JsonKey(name: 'post_id')
  final String? postId;

  final Post? post;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.createdAt,
    this.isRead = false,
    this.mediaUrls = const [],
    this.status = MessageDeliveryStatus.sent,
    this.isPost = false,
    this.postId,
    this.post,
  });

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    content,
    createdAt,
    isRead,
    mediaUrls,
    status,
    isPost,
    postId,
    post,
  ];
}
