// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_academics_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAcademicsModel _$UserAcademicsModelFromJson(Map<String, dynamic> json) =>
    UserAcademicsModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      collegeName: json['college_name'] as String,
      course: json['course'] as String,
      major: json['major'] as String?,
      startYear: (json['start_year'] as num?)?.toInt(),
      endYear: (json['end_year'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$UserAcademicsModelToJson(UserAcademicsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'college_name': instance.collegeName,
      'course': instance.course,
      'major': instance.major,
      'start_year': instance.startYear,
      'end_year': instance.endYear,
      'created_at': instance.createdAt.toIso8601String(),
    };
