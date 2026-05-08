// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventModel _$EventModelFromJson(Map<String, dynamic> json) => EventModel(
  id: json['id'] as String,
  organizerId: json['organizer_id'] as String,
  organizer: json['organizer'] == null
      ? null
      : User.fromJson(json['organizer'] as Map<String, dynamic>),
  title: json['title'] as String,
  category: json['category'] as String,
  about: json['about'] as String?,
  startDate: DateTime.parse(json['start_date'] as String),
  endDate: DateTime.parse(json['end_date'] as String),
  startTime: DateTime.parse(json['start_time'] as String),
  endTime: DateTime.parse(json['end_time'] as String),
  locationType: json['location_type'] as String,
  location: json['location'] as String?,
  meetingLink: json['meeting_link'] as String?,
  ticketPriceType: json['ticket_price_type'] as String,
  price: (json['price'] as num?)?.toDouble(),
  maxParticipant: (json['max_participant'] as num).toInt(),
  eventStatus: json['event_status'] as String,
  eligibility: json['eligibility'] as String?,
  eventImageUrl: json['event_image_url'] as String?,
  venue: json['venue'] as String?,
  registrationDeadline: json['registration_deadline'] == null
      ? null
      : DateTime.parse(json['registration_deadline'] as String),
  participationType: json['participation_type'] as String?,
  minTeamSize: (json['min_team_size'] as num?)?.toInt(),
  maxTeamSize: (json['max_team_size'] as num?)?.toInt(),
  upiId: json['upi_id'] as String?,
  conversationId: json['conversation_id'] as String?,
  customFields: json['custom_fields'] == null
      ? []
      : const EventCustomFieldListConverter().fromJson(
          json['custom_fields'] as List,
        ),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  activities: json['activity'] == null
      ? []
      : const EventActivityListConverter().fromJson(json['activity'] as List),
  prizes: json['prizes'] == null
      ? []
      : const EventPrizeListConverter().fromJson(json['prizes'] as List),
  faqs: json['faqs'] == null
      ? []
      : const EventFaqListConverter().fromJson(json['faqs'] as List),
  cohosts: json['cohosts'] == null
      ? []
      : const EventCohostListConverter().fromJson(json['cohosts'] as List),
  registrationCount: (json['registration_count'] as num?)?.toInt() ?? 0,
  isRegistered: json['is_registered'] as bool? ?? false,
  isBookmarked: json['is_bookmarked'] as bool? ?? false,
);

Map<String, dynamic> _$EventModelToJson(
  EventModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'organizer_id': instance.organizerId,
  'organizer': instance.organizer?.toJson(),
  'title': instance.title,
  'category': instance.category,
  'about': instance.about,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'start_time': instance.startTime.toIso8601String(),
  'end_time': instance.endTime.toIso8601String(),
  'location_type': instance.locationType,
  'location': instance.location,
  'meeting_link': instance.meetingLink,
  'ticket_price_type': instance.ticketPriceType,
  'price': instance.price,
  'max_participant': instance.maxParticipant,
  'event_status': instance.eventStatus,
  'eligibility': instance.eligibility,
  'event_image_url': instance.eventImageUrl,
  'venue': instance.venue,
  'registration_deadline': instance.registrationDeadline?.toIso8601String(),
  'participation_type': instance.participationType,
  'min_team_size': instance.minTeamSize,
  'max_team_size': instance.maxTeamSize,
  'created_at': instance.createdAt?.toIso8601String(),
  'activity': const EventActivityListConverter().toJson(instance.activities),
  'prizes': const EventPrizeListConverter().toJson(instance.prizes),
  'upi_id': instance.upiId,
  'conversation_id': instance.conversationId,
  'custom_fields': const EventCustomFieldListConverter().toJson(
    instance.customFields,
  ),
  'faqs': const EventFaqListConverter().toJson(instance.faqs),
  'cohosts': const EventCohostListConverter().toJson(instance.cohosts),
  'registration_count': instance.registrationCount,
  'is_registered': instance.isRegistered,
  'is_bookmarked': instance.isBookmarked,
};


