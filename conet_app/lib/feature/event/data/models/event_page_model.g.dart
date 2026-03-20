// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_page_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventPageModel _$EventPageModelFromJson(Map<String, dynamic> json) =>
    EventPageModel(
      events: json['events'] == null
          ? []
          : const EventListItemModelListConverter().fromJson(
              json['events'] as List,
            ),
      nextCursor: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
    );

Map<String, dynamic> _$EventPageModelToJson(EventPageModel instance) =>
    <String, dynamic>{
      'nextCursor': instance.nextCursor,
      'events': const EventListItemModelListConverter().toJson(instance.events),
      'hasMore': instance.hasMore,
      'pageSize': instance.pageSize,
    };
