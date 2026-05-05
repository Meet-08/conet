import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';
import 'package:equatable/equatable.dart';

enum ConversationType { direct, group }

class Conversation extends Equatable {
  final String id;

  final ConversationType type;

  /// Only present for direct conversations.
  final User? otherUser;

  /// Only present for group conversations.
  final String? name;

  /// Only present for group conversations.
  final String? description;

  final String? groupImageUrl;

  final String? createdBy;

  final bool onlyAdminAddMembers;

  final bool onlyAdminRemoveMembers;

  final bool onlyAdminEditGroup;

  final bool onlyAdminSendMessages;

  final String? currentUserRole;

  /// Only present for group conversations.
  final List<GroupMember> members;

  final String? lastMessage;

  final DateTime? updatedAt;

  final int unreadCount;

  final List<String> lastMessageMediaUrls;

  final bool isEvent;

  const Conversation({
    required this.id,
    this.type = ConversationType.direct,
    this.otherUser,
    this.name,
    this.description,
    this.groupImageUrl,
    this.createdBy,
    this.onlyAdminAddMembers = true,
    this.onlyAdminRemoveMembers = true,
    this.onlyAdminEditGroup = true,
    this.onlyAdminSendMessages = true,
    this.currentUserRole,
    this.members = const [],
    this.lastMessage,
    this.updatedAt,
    this.unreadCount = 0,
    this.lastMessageMediaUrls = const [],
    this.isEvent = false,
  });

  bool get isGroup => type == ConversationType.group;
  bool get isDirect => type == ConversationType.direct;
  bool get isAdmin => currentUserRole == 'admin';

  /// Display name: group name for groups, user name for DMs.
  String get displayName {
    if (isGroup) return name ?? 'Group';
    if (otherUser == null) return 'Unknown';
    final fullName = '${otherUser!.firstName} ${otherUser!.lastName}'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (otherUser!.username.isNotEmpty) return otherUser!.username;
    return 'User';
  }

  /// Display image URL: group image for groups, profile pic for DMs.
  String? get displayImageUrl {
    if (isGroup) return groupImageUrl;
    return otherUser?.profilePicUrl;
  }

  @override
  List<Object?> get props => [
    id,
    type,
    otherUser,
    name,
    description,
    groupImageUrl,
    createdBy,
    onlyAdminAddMembers,
    onlyAdminRemoveMembers,
    onlyAdminEditGroup,
    onlyAdminSendMessages,
    currentUserRole,
    members,
    lastMessage,
    updatedAt,
    unreadCount,
    lastMessageMediaUrls,
    isEvent,
  ];
}
