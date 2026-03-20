import 'package:conet_app/feature/event/data/models/event_model.dart';
import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:file_picker/file_picker.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_create_payload_model.g.dart';

@JsonSerializable(
  explicitToJson: true,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class EventCreatePayloadModel extends EventCreatePayload {
  @override
  @EventRequestTimeConverter()
  final DateTime startTime;

  @override
  @EventRequestTimeConverter()
  final DateTime endTime;

  @override
  @JsonKey(name: 'activity', defaultValue: [])
  @EventRequestActivityListConverter()
  final List<EventActivity> activities;

  @override
  @JsonKey(defaultValue: [])
  @EventPrizeListConverter()
  final List<EventPrize> prizes;

  @override
  @JsonKey(defaultValue: [])
  @EventFaqListConverter()
  final List<EventFaq> faqs;

  final bool publish;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final PlatformFile? eventImage;

  const EventCreatePayloadModel({
    required super.title,
    required super.category,
    super.about,
    required super.eventDate,
    required this.startTime,
    required this.endTime,
    required super.locationType,
    super.location,
    super.meetingLink,
    super.ticketPriceType = 'FREE',
    super.price,
    super.maxParticipant,
    super.eligibility,
    this.eventImage,
    this.activities = const [],
    this.prizes = const [],
    this.faqs = const [],
    required this.publish,
  }) : super(
         startTime: startTime,
         endTime: endTime,
         activities: activities,
         prizes: prizes,
         faqs: faqs,
         eventImage: eventImage,
       );

  factory EventCreatePayloadModel.fromJson(Map<String, dynamic> json) =>
      _$EventCreatePayloadModelFromJson(json);

  factory EventCreatePayloadModel.fromEntity(
    EventCreatePayload payload, {
    required bool publish,
  }) {
    return EventCreatePayloadModel(
      title: payload.title.trim(),
      category: payload.category.trim(),
      about: _nullableText(payload.about),
      eventDate: payload.eventDate,
      startTime: payload.startTime,
      endTime: payload.endTime,
      locationType: payload.locationType,
      location: _nullableText(payload.location),
      meetingLink: _nullableText(payload.meetingLink),
      ticketPriceType: payload.ticketPriceType,
      price: payload.price,
      maxParticipant: payload.maxParticipant,
      eligibility: _nullableText(payload.eligibility),
      eventImage: payload.eventImage,
      activities: payload.activities,
      prizes: payload.prizes,
      faqs: payload.faqs,
      publish: publish,
    );
  }

  Map<String, dynamic> toJson() => _$EventCreatePayloadModelToJson(this);

  static String? _nullableText(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class EventRequestTimeConverter implements JsonConverter<DateTime, String> {
  const EventRequestTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse('1970-01-01T$json');

  @override
  String toJson(DateTime object) {
    final hour = object.hour.toString().padLeft(2, '0');
    final minute = object.minute.toString().padLeft(2, '0');
    final second = object.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}

class EventRequestActivityListConverter
    implements JsonConverter<List<EventActivity>, List<dynamic>> {
  const EventRequestActivityListConverter();

  @override
  List<EventActivity> fromJson(List<dynamic> json) {
    return json.map((item) {
      final map = item as Map<String, dynamic>;
      return EventActivity(
        activityTime: const EventRequestTimeConverter().fromJson(
          map['activity_time'] as String,
        ),
        activityTitle: map['activity_title'] as String,
      );
    }).toList();
  }

  @override
  List<dynamic> toJson(List<EventActivity> object) {
    return object
        .map(
          (item) => {
            'activity_time': const EventRequestTimeConverter().toJson(
              item.activityTime,
            ),
            'activity_title': item.activityTitle.trim(),
          },
        )
        .toList();
  }
}
