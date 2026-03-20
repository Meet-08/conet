// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventActivityModel _$EventActivityModelFromJson(Map<String, dynamic> json) =>
    EventActivityModel(
      activityTime: DateTime.parse(json['activity_time'] as String),
      activityTitle: json['activity_title'] as String,
    );

Map<String, dynamic> _$EventActivityModelToJson(EventActivityModel instance) =>
    <String, dynamic>{
      'activity_time': instance.activityTime.toIso8601String(),
      'activity_title': instance.activityTitle,
    };
