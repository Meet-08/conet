// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventListItemModel _$EventListItemModelFromJson(Map<String, dynamic> json) =>
    EventListItemModel(
      id: json['id'] as String,
      organizerId: json['organizer_id'] as String?,
      isOrganizer: json['is_organizer'] as bool? ?? false,
      eventImageUrl: json['event_image_url'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      ticketPriceType: json['ticket_price_type'] as String,
      price: (json['price'] as num?)?.toDouble(),
      eventStartDate: DateTime.parse(json['event_start_date'] as String),
      maxParticipant: (json['max_participant'] as num?)?.toInt(),
      registrationCount: (json['registration_count'] as num?)?.toInt() ?? 0,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      venue: json['venue'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$EventListItemModelToJson(EventListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizer_id': instance.organizerId,
      'is_organizer': instance.isOrganizer,
      'event_image_url': instance.eventImageUrl,
      'title': instance.title,
      'category': instance.category,
      'ticket_price_type': instance.ticketPriceType,
      'price': instance.price,
      'event_start_date': instance.eventStartDate.toIso8601String(),
      'max_participant': instance.maxParticipant,
      'registration_count': instance.registrationCount,
      'is_bookmarked': instance.isBookmarked,
      'venue': instance.venue,
      'location': instance.location,
    };
