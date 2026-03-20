import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';

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
  final String? eligibility;
  final PlatformFile? eventImage;
  final List<EventActivity> activities;
  final List<EventPrize> prizes;
  final List<EventFaq> faqs;

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
    this.eligibility,
    this.eventImage,
    this.activities = const [],
    this.prizes = const [],
    this.faqs = const [],
  });

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
    eligibility,
    eventImage,
    activities,
    prizes,
    faqs,
  ];
}
