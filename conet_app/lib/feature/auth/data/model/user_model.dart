import 'package:conet_app/core/common/entities/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.username,
    required super.profilePicUrl,
    required super.userRole,
    required super.isVerified,
  });

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromJson(Map<String, dynamic> source) =>
      _$UserModelFromJson(source);

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? profilePicUrl,
    UserRole? userRole,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      userRole: userRole ?? this.userRole,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
