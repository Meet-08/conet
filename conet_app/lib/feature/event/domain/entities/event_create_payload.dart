import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:json_annotation/json_annotation.dart';

class EventCreatePayload extends Equatable {
  final String title;
  final String category;
  final String? about;
  final DateTime eventDate;
  final DateTime startTime;
  final DateTime endTime;
  final String locationType;
  final String? location;
  final String? meetingLink;
  final String ticketPriceType;
  final double? price;
  final int? maxParticipant;
  final String? venue;
  final DateTime? registrationDeadline;
  final String? participationType;
  final int? minTeamSize;
  final int? maxTeamSize;
  final List<EventCustomField> customFields;
  final String? eligibility;
  final PlatformFile? eventImage;
  final List<EventActivity> activities;
  final List<EventPrize> prizes;
  final List<EventFaq> faqs;
  final List<String> cohostUserIds;

  @JsonKey(name: 'conversation_id')
  final String? conversationId;

  const EventCreatePayload({
    required this.title,
    required this.category,
    this.about,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.locationType,
    this.location,
    this.meetingLink,
    this.ticketPriceType = 'FREE',
    this.price,
    this.maxParticipant,
    this.venue,
    this.registrationDeadline,
    this.participationType,
    this.minTeamSize,
    this.maxTeamSize,
    this.customFields = const [],
    this.eligibility,
    this.eventImage,
    this.activities = const [],
    this.prizes = const [],
    this.faqs = const [],
    this.cohostUserIds = const [],
    this.conversationId,
  });

  EventCreatePayload copyWith({
    String? title,
    String? category,
    String? about,
    DateTime? eventDate,
    DateTime? startTime,
    DateTime? endTime,
    String? locationType,
    String? location,
    String? meetingLink,
    String? ticketPriceType,
    double? price,
    int? maxParticipant,
    String? venue,
    DateTime? registrationDeadline,
    String? participationType,
    int? minTeamSize,
    int? maxTeamSize,
    List<EventCustomField>? customFields,
    String? eligibility,
    PlatformFile? eventImage,
    List<EventActivity>? activities,
    List<EventPrize>? prizes,
    List<EventFaq>? faqs,
    List<String>? cohostUserIds,
    String? conversationId,
  }) {
    return EventCreatePayload(
      title: title ?? this.title,
      category: category ?? this.category,
      about: about ?? this.about,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      locationType: locationType ?? this.locationType,
      location: location ?? this.location,
      meetingLink: meetingLink ?? this.meetingLink,
      ticketPriceType: ticketPriceType ?? this.ticketPriceType,
      price: price ?? this.price,
      maxParticipant: maxParticipant ?? this.maxParticipant,
      venue: venue ?? this.venue,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      participationType: participationType ?? this.participationType,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      customFields: customFields ?? this.customFields,
      eligibility: eligibility ?? this.eligibility,
      eventImage: eventImage ?? this.eventImage,
      activities: activities ?? this.activities,
      prizes: prizes ?? this.prizes,
      faqs: faqs ?? this.faqs,
      cohostUserIds: cohostUserIds ?? this.cohostUserIds,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  List<Object?> get props => [
    title,
    category,
    about,
    eventDate,
    startTime,
    endTime,
    locationType,
    location,
    meetingLink,
    ticketPriceType,
    price,
    maxParticipant,
    venue,
    registrationDeadline,
    participationType,
    minTeamSize,
    maxTeamSize,
    customFields,
    eligibility,
    eventImage,
    activities,
    prizes,
    faqs,
    cohostUserIds,
    conversationId,
  ];
}
