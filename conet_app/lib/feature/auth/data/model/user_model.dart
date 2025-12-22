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
}
