import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_list_item_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EventListItemModel extends EventListItem {
  const EventListItemModel({
    required super.id,
    super.conversationId,
    super.organizerId,
    super.isOrganizer,
    super.eventImageUrl,
    required super.title,
    required super.category,
    required super.ticketPriceType,
    super.price,
    required super.eventStartDate,
    super.maxParticipant,
    super.registrationCount,
    super.isBookmarked,
    super.venue,
    super.location,
  });

  factory EventListItemModel.fromJson(Map<String, dynamic> json) =>
      _$EventListItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventListItemModelToJson(this);

  factory EventListItemModel.fromEntity(EventListItem entity) {
    return EventListItemModel(
      id: entity.id,
      conversationId: entity.conversationId,
      organizerId: entity.organizerId,
      isOrganizer: entity.isOrganizer,
      eventImageUrl: entity.eventImageUrl,
      title: entity.title,
      category: entity.category,
      ticketPriceType: entity.ticketPriceType,
      price: entity.price,
      eventStartDate: entity.eventStartDate,
      maxParticipant: entity.maxParticipant,
      registrationCount: entity.registrationCount,
      isBookmarked: entity.isBookmarked,
      venue: entity.venue,
      location: entity.location,
    );
  }
}

class EventListItemModelListConverter
    implements JsonConverter<List<EventListItem>, List<dynamic>> {
  const EventListItemModelListConverter();

  @override
  List<EventListItem> fromJson(List<dynamic> json) {
    return json
        .map(
          (item) => EventListItemModel.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  @override
  List<dynamic> toJson(List<EventListItem> object) {
    return object
        .map((item) => EventListItemModel.fromEntity(item).toJson())
        .toList();
  }
}
