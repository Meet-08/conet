import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

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

class User extends Equatable {
  final String id;
  final String email;

  @JsonKey(name: 'first_name', defaultValue: "")
  final String firstName;

  @JsonKey(name: 'last_name', defaultValue: "")
  final String lastName;

  @JsonKey(defaultValue: "")
  final String username;

  @JsonKey(name: 'profile_pic_url', defaultValue: "")
  final String profilePicUrl;

  @JsonKey(name: 'user_role', defaultValue: UserRole.user)
  final UserRole userRole;

  @JsonKey(name: 'is_verified', defaultValue: false)
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.profilePicUrl,
    required this.userRole,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    username,
    profilePicUrl,
    userRole,
    isVerified,
  ];
}
