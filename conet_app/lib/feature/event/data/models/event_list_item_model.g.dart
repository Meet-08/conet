// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventListItemModel _$EventListItemModelFromJson(Map<String, dynamic> json) =>
    EventListItemModel(
      id: json['id'] as String,
      eventImageUrl: json['event_image_url'] as String?,
      title: json['title'] as String,
      category: json['category'] as String,
      ticketPriceType: json['ticket_price_type'] as String,
      price: (json['price'] as num?)?.toDouble(),
      eventStartDate: DateTime.parse(json['event_start_date'] as String),
      venue: json['venue'] as String?,
      location: json['location'] as String?,
    );

Map<String, dynamic> _$EventListItemModelToJson(EventListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'event_image_url': instance.eventImageUrl,
      'title': instance.title,
      'category': instance.category,
      'ticket_price_type': instance.ticketPriceType,
      'price': instance.price,
      'event_start_date': instance.eventStartDate.toIso8601String(),
      'venue': instance.venue,
      'location': instance.location,
    };
