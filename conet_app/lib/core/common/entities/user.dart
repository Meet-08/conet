import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

enum UserRole {
  user,
  admin;

  static UserRole fromMap(Map<String, dynamic> map) {
    final roleValue = map['role'];
    if (roleValue is String) {
      try {
        return UserRole.values.firstWhere((role) => role.name == roleValue);
      } on StateError {
        return UserRole.user;
      }
    }
    return UserRole.user;
  }
}

@JsonSerializable()
class User extends Equatable {
  final String id;

  @JsonKey(defaultValue: "")
  final String email;

  @JsonKey(name: 'first_name', defaultValue: "")
  final String firstName;

  @JsonKey(name: 'last_name', defaultValue: "")
  final String lastName;

  @JsonKey(defaultValue: "")
  final String username;

  @JsonKey(name: 'profile_pic_url')
  final String? profilePicUrl;

  @JsonKey(name: 'user_role', defaultValue: UserRole.user)
  final UserRole userRole;

  @JsonKey(name: 'unseen_notification_count', defaultValue: 0)
  final int unseenNotificationCount;

  @JsonKey(name: 'is_online', defaultValue: false)
  final bool isOnline;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profilePicUrl,
    required this.userRole,
    this.unseenNotificationCount = 0,
    this.isOnline = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    username,
    profilePicUrl,
    userRole,
    unseenNotificationCount,
    isOnline,
  ];
}
