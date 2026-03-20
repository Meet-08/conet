import 'package:conet_app/feature/event/domain/entities/event_activity.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_activity_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EventActivityModel extends EventActivity {
  const EventActivityModel({
    required super.activityTime,
    required super.activityTitle,
  });

  factory EventActivityModel.fromJson(Map<String, dynamic> json) =>
      _$EventActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventActivityModelToJson(this);

  factory EventActivityModel.fromEntity(EventActivity entity) {
    return EventActivityModel(
      activityTime: entity.activityTime,
      activityTitle: entity.activityTitle,
    );
  }
}
