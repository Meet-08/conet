import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/event/data/models/event_activity_model.dart';
import 'package:conet_app/feature/event/data/models/event_cohost_model.dart';
import 'package:conet_app/feature/event/data/models/event_faq_model.dart';
import 'package:conet_app/feature/event/data/models/event_prize_model.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:conet_app/feature/event/domain/entities/event_custom_field.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class EventModel extends Event {
  @override
  @JsonKey(name: 'activity', defaultValue: [])
  @EventActivityListConverter()
  final List<EventActivity> activities;

  @override
  @JsonKey(defaultValue: [])
  @EventPrizeListConverter()
  final List<EventPrize> prizes;

  @override
  @JsonKey(name: 'upi_id')
  final String? upiId;

  @override
  @JsonKey(name: 'conversation_id')
  final String? conversationId;

  @override
  @JsonKey(name: 'custom_fields', defaultValue: [])
  @EventCustomFieldListConverter()
  final List<EventCustomField> customFields;
  @override
  @JsonKey(defaultValue: [])
  @EventFaqListConverter()
  final List<EventFaq> faqs;

  @override
  @JsonKey(defaultValue: [])
  @EventCohostListConverter()
  final List<EventCohost> cohosts;

  @override
  @JsonKey(defaultValue: 0)
  final int registrationCount;

  @override
  @JsonKey(defaultValue: false)
  final bool isRegistered;

  @override
  @JsonKey(defaultValue: false)
  final bool isBookmarked;

  const EventModel({
    required super.id,
    required super.organizerId,
    super.organizer,
    required super.title,
    required super.category,
    super.about,
    required super.startDate,
    required super.endDate,
    required super.startTime,
    required super.endTime,
    required super.locationType,
    super.location,
    super.meetingLink,
    required super.ticketPriceType,
    super.price,
    required super.maxParticipant,
    required super.eventStatus,
    super.eligibility,
    super.instructions,
    super.eventImageUrl,
    super.venue,
    super.registrationDeadline,
    super.participationType,
    super.minTeamSize,
    super.maxTeamSize,
    this.upiId,
    this.conversationId,
    this.customFields = const [],
    super.createdAt,
    this.activities = const [],
    this.prizes = const [],
    this.faqs = const [],
    this.cohosts = const [],
    this.registrationCount = 0,
    this.isRegistered = false,
    this.isBookmarked = false,
  }) : super(
         activities: activities,
         prizes: prizes,
         faqs: faqs,
         cohosts: cohosts,
         upiId: upiId,
         conversationId: conversationId,
         customFields: customFields,
         registrationCount: registrationCount,
         isRegistered: isRegistered,
         isBookmarked: isBookmarked,
       );

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);

  factory EventModel.fromEntity(Event entity) {
    return EventModel(
      id: entity.id,
      organizerId: entity.organizerId,
      organizer: entity.organizer,
      title: entity.title,
      category: entity.category,
      about: entity.about,
      startDate: entity.startDate,
      endDate: entity.endDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      locationType: entity.locationType,
      location: entity.location,
      meetingLink: entity.meetingLink,
      ticketPriceType: entity.ticketPriceType,
      price: entity.price,
      maxParticipant: entity.maxParticipant,
      eventStatus: entity.eventStatus,
      eligibility: entity.eligibility,
      instructions: entity.instructions,
      eventImageUrl: entity.eventImageUrl,
      venue: entity.venue,
      registrationDeadline: entity.registrationDeadline,
      participationType: entity.participationType,
      minTeamSize: entity.minTeamSize,
      maxTeamSize: entity.maxTeamSize,
      upiId: entity.upiId,
      conversationId: entity.conversationId,
      customFields: entity.customFields,
      createdAt: entity.createdAt,
      activities: entity.activities,
      prizes: entity.prizes,
      faqs: entity.faqs,
      cohosts: entity.cohosts,
      registrationCount: entity.registrationCount,
      isRegistered: entity.isRegistered,
      isBookmarked: entity.isBookmarked,
    );
  }
}

class EventActivityListConverter
    implements JsonConverter<List<EventActivity>, List<dynamic>> {
  const EventActivityListConverter();

  @override
  List<EventActivity> fromJson(List<dynamic> json) {
    return json
        .map(
          (item) => EventActivityModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  List<dynamic> toJson(List<EventActivity> object) {
    return object
        .map((item) => EventActivityModel.fromEntity(item).toJson())
        .toList();
  }
}

class EventPrizeListConverter
    implements JsonConverter<List<EventPrize>, List<dynamic>> {
  const EventPrizeListConverter();

  @override
  List<EventPrize> fromJson(List<dynamic> json) {
    return json
        .map((item) => EventPrizeModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<EventPrize> object) {
    return object
        .map((item) => EventPrizeModel.fromEntity(item).toJson())
        .toList();
  }
}

class EventFaqListConverter
    implements JsonConverter<List<EventFaq>, List<dynamic>> {
  const EventFaqListConverter();

  @override
  List<EventFaq> fromJson(List<dynamic> json) {
    return json
        .map((item) => EventFaqModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<EventFaq> object) {
    return object
        .map((item) => EventFaqModel.fromEntity(item).toJson())
        .toList();
  }
}

class EventCohostListConverter
    implements JsonConverter<List<EventCohost>, List<dynamic>> {
  const EventCohostListConverter();

  @override
  List<EventCohost> fromJson(List<dynamic> json) {
    return json
        .map((item) => EventCohostModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<EventCohost> object) {
    return object
        .map((item) => EventCohostModel.fromEntity(item).toJson())
        .toList();
  }
}

class EventCustomFieldListConverter
    implements JsonConverter<List<EventCustomField>, List<dynamic>> {
  const EventCustomFieldListConverter();

  @override
  List<EventCustomField> fromJson(List<dynamic> json) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(EventCustomField.fromJson)
        .where((field) => field.key.isNotEmpty)
        .toList(growable: false);
  }

  @override
  List<dynamic> toJson(List<EventCustomField> object) {
    return object.map((field) => field.toJson()).toList(growable: false);
  }
}
