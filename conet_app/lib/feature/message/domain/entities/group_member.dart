import 'package:conet_app/core/common/entities/user.dart';
import 'package:equatable/equatable.dart';

class GroupMember extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String? profilePicUrl;
  final String role;
  final DateTime? joinedAt;

  const GroupMember({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    this.profilePicUrl,
    this.role = 'member',
    this.joinedAt,
  });

  bool get isAdmin => role == 'admin';

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    return 'User';
  }

  /// Convert to a core User entity (for reuse in widgets).
  User toUser() => User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    username: username,
    profilePicUrl: profilePicUrl,
    userRole: UserRole.user,
  );

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    username,
    profilePicUrl,
    role,
    joinedAt,
  ];
}
