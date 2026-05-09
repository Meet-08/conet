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
  instructions: json['instructions'] as String?,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
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
  venue: json['venue'] as String?,
  registrationDeadline: json['registration_deadline'] == null
      ? null
      : DateTime.parse(json['registration_deadline'] as String),
  participationType: json['participation_type'] as String?,
  minTeamSize: (json['min_team_size'] as num?)?.toInt(),
  maxTeamSize: (json['max_team_size'] as num?)?.toInt(),
  customFields: json['custom_fields'] == null
      ? []
      : const EventRequestCustomFieldListConverter().fromJson(
          json['custom_fields'] as List,
        ),
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
  conversationId: json['conversation_id'] as String?,
  publish: json['publish'] as bool,
);

Map<String, dynamic> _$EventCreatePayloadModelToJson(
  EventCreatePayloadModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'category': instance.category,
  'about': ?instance.about,
  'instructions': ?instance.instructions,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'location_type': instance.locationType,
  'location': ?instance.location,
  'meeting_link': ?instance.meetingLink,
  'ticket_price_type': instance.ticketPriceType,
  'price': ?instance.price,
  'max_participant': ?instance.maxParticipant,
  'eligibility': ?instance.eligibility,
  'conversation_id': ?instance.conversationId,
  'start_time': const EventRequestTimeConverter().toJson(instance.startTime),
  'end_time': const EventRequestTimeConverter().toJson(instance.endTime),
  'activity': const EventRequestActivityListConverter().toJson(
    instance.activities,
  ),
  'prizes': const EventPrizeListConverter().toJson(instance.prizes),
  'faqs': const EventFaqListConverter().toJson(instance.faqs),
  'venue': ?instance.venue,
  'registration_deadline': ?instance.registrationDeadline?.toIso8601String(),
  'participation_type': ?instance.participationType,
  'min_team_size': ?instance.minTeamSize,
  'max_team_size': ?instance.maxTeamSize,
  'custom_fields': const EventRequestCustomFieldListConverter().toJson(
    instance.customFields,
  ),
  'publish': instance.publish,
};
