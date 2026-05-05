import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/message/data/models/group_member_model.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:conet_app/feature/message/domain/entities/group_member.dart';

class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    super.type,
    super.otherUser,
    super.name,
    super.description,
    super.groupImageUrl,
    super.createdBy,
    super.onlyAdminAddMembers,
    super.onlyAdminRemoveMembers,
    super.onlyAdminEditGroup,
    super.onlyAdminSendMessages,
    super.currentUserRole,
    super.members,
    super.lastMessage,
    super.updatedAt,
    super.unreadCount,
    super.lastMessageMediaUrls,
    super.isEvent,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'direct';
    final conversationType = typeStr == 'group'
        ? ConversationType.group
        : ConversationType.direct;

    User? otherUser;
    if (json['other_user'] != null && json['other_user'] is Map) {
      otherUser = User.fromJson(json['other_user'] as Map<String, dynamic>);
    }

    final membersList = <GroupMember>[];
    if (json['members'] != null && json['members'] is List) {
      for (final m in json['members'] as List) {
        if (m is Map<String, dynamic>) {
          membersList.add(GroupMemberModel.fromJson(m));
        }
      }
    }

    return ConversationModel(
      id: json['id'] as String,
      type: conversationType,
      otherUser: otherUser,
      name: json['name'] as String?,
      description: json['description'] as String?,
      groupImageUrl: json['group_image_url'] as String?,
      createdBy: json['created_by'] as String?,
      onlyAdminAddMembers: json['only_admin_add_members'] as bool? ?? true,
      onlyAdminRemoveMembers:
          json['only_admin_remove_members'] as bool? ?? true,
      onlyAdminEditGroup: json['only_admin_edit_group'] as bool? ?? true,
      onlyAdminSendMessages: json['only_admin_send_messages'] as bool? ?? true,
      currentUserRole: json['current_user_role'] as String?,
      members: membersList,
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      lastMessageMediaUrls:
          (json['last_message_media_urls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isEvent: json['is_event'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'type': type == ConversationType.group ? 'group' : 'direct',
    'other_user': otherUser != null ? (otherUser as User).toJson() : null,
    'name': name,
    'description': description,
    'group_image_url': groupImageUrl,
    'created_by': createdBy,
    'only_admin_add_members': onlyAdminAddMembers,
    'only_admin_remove_members': onlyAdminRemoveMembers,
    'only_admin_edit_group': onlyAdminEditGroup,
    'only_admin_send_messages': onlyAdminSendMessages,
    'current_user_role': currentUserRole,
    'members': members
        .map(
          (m) => GroupMemberModel(
            id: m.id,
            email: m.email,
            firstName: m.firstName,
            lastName: m.lastName,
            username: m.username,
            profilePicUrl: m.profilePicUrl,
            role: m.role,
            joinedAt: m.joinedAt,
          ).toJson(),
        )
        .toList(),
    'last_message': lastMessage,
    'updated_at': updatedAt?.toIso8601String(),
    'unread_count': unreadCount,
    'last_message_media_urls': lastMessageMediaUrls,
    'is_event': isEvent,
  };
}
