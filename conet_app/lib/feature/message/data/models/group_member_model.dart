import 'package:conet_app/feature/message/domain/entities/group_member.dart';

class GroupMemberModel extends GroupMember {
  const GroupMemberModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.username,
    super.profilePicUrl,
    super.role,
    super.joinedAt,
  });

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    return GroupMemberModel(
      id: json['id'] as String,
      email: (json['email'] as String?) ?? '',
      firstName: (json['first_name'] as String?) ?? '',
      lastName: (json['last_name'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      profilePicUrl: json['profile_pic_url'] as String?,
      role: (json['role'] as String?) ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'username': username,
    'profile_pic_url': profilePicUrl,
    'role': role,
    'joined_at': joinedAt?.toIso8601String(),
  };
}
