// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_create_payload_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventCreatePayloadModel _$EventCreatePayloadModelFromJson(
  Map<String, dynamic> json,
) => EventCreatePayloadModel(
  title: json['title'] as String,
  category: json['category'] as String,
  about: json['about'] as String?,
  eventDate: DateTime.parse(json['event_date'] as String),
  startTime: const EventRequestTimeConverter().fromJson(
    json['start_time'] as String,
  ),
  endTime: const EventRequestTimeConverter().fromJson(
    json['end_time'] as String,
  ),
  locationType: json['location_type'] as String,
  location: json['location'] as String?,
  meetingLink: json['meeting_link'] as String?,
  ticketPriceType: json['ticket_price_type'] as String? ?? 'FREE',
  price: (json['price'] as num?)?.toDouble(),
  maxParticipant: (json['max_participant'] as num?)?.toInt(),
  eligibility: json['eligibility'] as String?,
  activities: json['activity'] == null
      ? []
      : const EventRequestActivityListConverter().fromJson(
          json['activity'] as List,
        ),
  prizes: json['prizes'] == null
      ? []
      : const EventPrizeListConverter().fromJson(json['prizes'] as List),
  faqs: json['faqs'] == null
      ? []
      : const EventFaqListConverter().fromJson(json['faqs'] as List),
  publish: json['publish'] as bool,
);

Map<String, dynamic> _$EventCreatePayloadModelToJson(
  EventCreatePayloadModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'category': instance.category,
  'about': ?instance.about,
  'event_date': instance.eventDate.toIso8601String(),
  'location_type': instance.locationType,
  'location': ?instance.location,
  'meeting_link': ?instance.meetingLink,
  'ticket_price_type': instance.ticketPriceType,
  'price': ?instance.price,
  'max_participant': ?instance.maxParticipant,
  'eligibility': ?instance.eligibility,
  'start_time': const EventRequestTimeConverter().toJson(instance.startTime),
  'end_time': const EventRequestTimeConverter().toJson(instance.endTime),
  'activity': const EventRequestActivityListConverter().toJson(
    instance.activities,
  ),
  'prizes': const EventPrizeListConverter().toJson(instance.prizes),
  'faqs': const EventFaqListConverter().toJson(instance.faqs),
  'publish': instance.publish,
};
