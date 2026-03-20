import 'package:conet_app/feature/event/data/models/event_list_item_model.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_page_model.g.dart';

@JsonSerializable(explicitToJson: true)
class EventPageModel extends EventPage {
  @override
  @JsonKey(defaultValue: [])
  @EventListItemModelListConverter()
  final List<EventListItem> events;

  @override
  @JsonKey(defaultValue: false)
  final bool hasMore;

  @override
  @JsonKey(name: 'pageSize', defaultValue: 20)
  final int pageSize;

  const EventPageModel({
    required this.events,
    required super.nextCursor,
    required this.hasMore,
    required this.pageSize,
  }) : super(events: events, hasMore: hasMore, pageSize: pageSize);

  factory EventPageModel.fromJson(Map<String, dynamic> json) =>
      _$EventPageModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventPageModelToJson(this);

  factory EventPageModel.fromEntity(EventPage entity) {
    return EventPageModel(
      events: entity.events,
      nextCursor: entity.nextCursor,
      hasMore: entity.hasMore,
      pageSize: entity.pageSize,
    );
  }
}
