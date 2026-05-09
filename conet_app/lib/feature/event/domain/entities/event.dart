import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Event extends Equatable {
  final String id;

  @JsonKey(name: 'organizer_id')
  final String organizerId;

  final User? organizer;
  final String title;
  final String category;
  final String? about;

  @JsonKey(name: 'start_date')
  final DateTime startDate;

  @JsonKey(name: 'end_date')
  final DateTime endDate;

  @JsonKey(name: 'start_time')
  final DateTime startTime;

  @JsonKey(name: 'end_time')
  final DateTime endTime;

  @JsonKey(name: 'location_type')
  final String locationType;
  final String? location;

  @JsonKey(name: 'meeting_link')
  final String? meetingLink;

  @JsonKey(name: 'ticket_price_type')
  final String ticketPriceType;
  final double? price;

  @JsonKey(name: 'max_participant')
  final int maxParticipant;

  @JsonKey(name: 'event_status')
  final String eventStatus;

  final String? eligibility;
  final String? instructions;

  @JsonKey(name: 'event_image_url')
  final String? eventImageUrl;
  final String? venue;

  @JsonKey(name: 'registration_deadline')
  final DateTime? registrationDeadline;

  @JsonKey(name: 'participation_type')
  final String? participationType;

  @JsonKey(name: 'min_team_size')
  final int? minTeamSize;

  @JsonKey(name: 'max_team_size')
  final int? maxTeamSize;

  @JsonKey(name: 'upi_id')
  final String? upiId;

  @JsonKey(name: 'conversation_id')
  final String? conversationId;

  @JsonKey(name: 'custom_fields')
  final List<EventCustomField> customFields;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  final List<EventActivity> activities;
  final List<EventPrize> prizes;
  final List<EventFaq> faqs;
  final List<EventCohost> cohosts;

  @JsonKey(name: 'registration_count')
  final int registrationCount;

  @JsonKey(name: 'is_registered')
  final bool isRegistered;

  @JsonKey(name: 'is_bookmarked')
  final bool isBookmarked;

  const Event({
    required this.id,
    required this.organizerId,
    this.organizer,
    required this.title,
    required this.category,
    this.about,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.locationType,
    this.location,
    this.meetingLink,
    required this.ticketPriceType,
    this.price,
    required this.maxParticipant,
    required this.eventStatus,
    this.eligibility,
    this.instructions,
    this.eventImageUrl,
    this.venue,
    this.registrationDeadline,
    this.participationType,
    this.minTeamSize,
    this.maxTeamSize,
    this.upiId,
    this.conversationId,
    this.customFields = const [],
    this.createdAt,
    this.activities = const [],
    this.prizes = const [],
    this.faqs = const [],
    this.cohosts = const [],
    this.registrationCount = 0,
    this.isRegistered = false,
    this.isBookmarked = false,
  });

  bool get isOnline => locationType == 'ONLINE';

  bool get isPaid => ticketPriceType == 'PAID';

  Event copyWith({
    String? id,
    String? organizerId,
    User? organizer,
    String? title,
    String? category,
    String? about,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? startTime,
    DateTime? endTime,
    String? locationType,
    String? location,
    String? meetingLink,
    String? ticketPriceType,
    double? price,
    int? maxParticipant,
    String? eventStatus,
    String? eligibility,
    String? instructions,
    String? eventImageUrl,
    String? venue,
    DateTime? registrationDeadline,
    String? participationType,
    int? minTeamSize,
    int? maxTeamSize,
    String? upiId,
    String? conversationId,
    List<EventCustomField>? customFields,
    DateTime? createdAt,
    List<EventActivity>? activities,
    List<EventPrize>? prizes,
    List<EventFaq>? faqs,
    List<EventCohost>? cohosts,
    int? registrationCount,
    bool? isRegistered,
    bool? isBookmarked,
  }) {
    return Event(
      id: id ?? this.id,
      organizerId: organizerId ?? this.organizerId,
      organizer: organizer ?? this.organizer,
      title: title ?? this.title,
      category: category ?? this.category,
      about: about ?? this.about,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      locationType: locationType ?? this.locationType,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      ticketPriceType: ticketPriceType ?? this.ticketPriceType,
      price: price ?? this.price,
      maxParticipant: maxParticipant ?? this.maxParticipant,
      eventStatus: eventStatus ?? this.eventStatus,
      eligibility: eligibility ?? this.eligibility,
      instructions: instructions ?? this.instructions,
      eventImageUrl: eventImageUrl ?? this.eventImageUrl,
      venue: venue ?? this.venue,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      participationType: participationType ?? this.participationType,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      upiId: upiId ?? this.upiId,
      conversationId: conversationId ?? this.conversationId,
      customFields: customFields ?? this.customFields,
      createdAt: createdAt ?? this.createdAt,
      activities: activities ?? this.activities,
      prizes: prizes ?? this.prizes,
      faqs: faqs ?? this.faqs,
      cohosts: cohosts ?? this.cohosts,
      registrationCount: registrationCount ?? this.registrationCount,
      isRegistered: isRegistered ?? this.isRegistered,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
    id,
    organizerId,
    organizer,
    title,
    category,
    about,
    startDate,
    endDate,
    startTime,
    endTime,
    locationType,
    location,
    meetingLink,
    ticketPriceType,
    price,
    maxParticipant,
    eventStatus,
    eligibility,
    instructions,
    eventImageUrl,
    venue,
    registrationDeadline,
    participationType,
    minTeamSize,
    maxTeamSize,
    upiId,
    conversationId,
    customFields,
    createdAt,
    activities,
    prizes,
    faqs,
    cohosts,
    registrationCount,
    isRegistered,
    isBookmarked,
  ];
}
