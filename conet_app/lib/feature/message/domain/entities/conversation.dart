import 'package:conet_app/core/common/entities/user.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Conversation extends Equatable {
  final String id;

  @JsonKey(name: 'other_user')
  final User otherUser;

  @JsonKey(name: 'last_message')
  final String? lastMessage;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @JsonKey(name: 'unread_count', defaultValue: 0)
  final int unreadCount;

  @JsonKey(name: 'last_message_media_urls', defaultValue: [])
  final List<String> lastMessageMediaUrls;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    this.updatedAt,
    this.unreadCount = 0,
    this.lastMessageMediaUrls = const [],
  });

  @override
  List<Object?> get props => [
    id,
    otherUser,
    lastMessage,
    updatedAt,
    unreadCount,
    lastMessageMediaUrls,
  ];
}
