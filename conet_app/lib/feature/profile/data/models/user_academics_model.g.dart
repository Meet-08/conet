// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_academics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAcademicsModel _$UserAcademicsModelFromJson(Map<String, dynamic> json) =>
    UserAcademicsModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      collegeName: json['collegeName'] as String,
      course: json['course'] as String,
      major: json['major'] as String?,
      startYear: (json['startYear'] as num?)?.toInt(),
      endYear: (json['endYear'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$UserAcademicsModelToJson(UserAcademicsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'collegeName': instance.collegeName,
      'course': instance.course,
      'major': instance.major,
      'startYear': instance.startYear,
      'endYear': instance.endYear,
      'createdAt': instance.createdAt.toIso8601String(),
    };
