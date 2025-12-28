import 'package:conet_app/core/common/entities/user.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.username,
    required super.profilePicUrl,
    required super.userRole,
    required super.isVerified,
  });

  @override
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromJson(Map<String, dynamic> source) =>
      _$UserModelFromJson(source);

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? username,
    String? profilePicUrl,
    UserRole? userRole,
    bool? isVerified,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
      userRole: userRole ?? this.userRole,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
