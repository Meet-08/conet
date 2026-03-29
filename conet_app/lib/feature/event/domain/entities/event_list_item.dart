import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class EventListItem extends Equatable {
  final String id;

  @JsonKey(name: 'event_image_url')
  final String? eventImageUrl;

  final String title;
  final String category;

  @JsonKey(name: 'ticket_price_type')
  final String ticketPriceType;

  final double? price;

  @JsonKey(name: 'event_start_date')
  final DateTime eventStartDate;

  @JsonKey(name: 'max_participant')
  final int? maxParticipant;

  @JsonKey(name: 'registration_count')
  final int registrationCount;

  @JsonKey(name: 'is_bookmarked')
  final bool isBookmarked;

  final String? venue;
  final String? location;

  const EventListItem({
    required this.id,
    this.eventImageUrl,
    required this.title,
    required this.category,
    required this.ticketPriceType,
    this.price,
    required this.eventStartDate,
    this.maxParticipant,
    this.registrationCount = 0,
    this.isBookmarked = false,
    this.venue,
    this.location,
  });

  bool get isPaid => ticketPriceType == 'PAID';

  EventListItem copyWith({
    String? id,
    String? eventImageUrl,
    String? title,
    String? category,
    String? ticketPriceType,
    double? price,
    DateTime? eventStartDate,
    int? maxParticipant,
    int? registrationCount,
    bool? isBookmarked,
    String? venue,
    String? location,
  }) {
    return EventListItem(
      id: id ?? this.id,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      title: title ?? this.title,
      category: category ?? this.category,
      ticketPriceType: ticketPriceType ?? this.ticketPriceType,
      price: price ?? this.price,
      eventStartDate: eventStartDate ?? this.eventStartDate,
      maxParticipant: maxParticipant ?? this.maxParticipant,
      registrationCount: registrationCount ?? this.registrationCount,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      venue: venue ?? this.venue,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [
    id,
    eventImageUrl,
    title,
    category,
    ticketPriceType,
    price,
    eventStartDate,
    maxParticipant,
    registrationCount,
    isBookmarked,
    venue,
    location,
  ];
}
