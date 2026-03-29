import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_academics_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserAcademicsModel extends UserAcademics {
  const UserAcademicsModel({
    required super.id,
    required super.userId,
    required super.collegeName,
    super.degree,
    required super.course,
    super.major,
    super.startYear,
    super.endYear,
    required super.createdAt,
  });

  factory UserAcademicsModel.fromJson(Map<String, dynamic> json) =>
      _$UserAcademicsModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserAcademicsModelToJson(this);

  factory UserAcademicsModel.fromEntity(UserAcademics entity) {
    return UserAcademicsModel(
      id: entity.id,
      userId: entity.userId,
      collegeName: entity.collegeName,
      degree: entity.degree,
      course: entity.course,
      major: entity.major,
      startYear: entity.startYear,
      endYear: entity.endYear,
      createdAt: entity.createdAt,
    );
  }
}

class UserAcademicsListConverter
    implements JsonConverter<List<UserAcademics>, List<dynamic>> {
  const UserAcademicsListConverter();

  @override
  List<UserAcademics> fromJson(List<dynamic> json) {
    return json
        .map((e) => UserAcademicsModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<UserAcademics> objects) {
    return objects
        .map((e) => UserAcademicsModel.fromEntity(e).toJson())
        .toList();
  }
}
