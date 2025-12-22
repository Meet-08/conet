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

  @JsonKey(defaultValue: "")
  final String fullName;

  @JsonKey(defaultValue: "")
  final String username;

  @JsonKey(defaultValue: "")
  final String profilePicUrl;

  @JsonKey(defaultValue: UserRole.user)
  final UserRole userRole;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    required this.profilePicUrl,
    required this.userRole,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    username,
    profilePicUrl,
    userRole,
    isVerified,
  ];
}
