import 'package:conet_app/feature/event/domain/entities/event_cohost.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_cohost_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class EventCohostModel extends EventCohost {
  const EventCohostModel({
    required super.id,
    required super.userId,
    required super.username,
    super.firstName,
    super.lastName,
    super.profilePicUrl,
  });

  factory EventCohostModel.fromJson(Map<String, dynamic> json) =>
      _$EventCohostModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventCohostModelToJson(this);

  factory EventCohostModel.fromEntity(EventCohost entity) {
    return EventCohostModel(
      id: entity.id,
      userId: entity.userId,
      username: entity.username,
      firstName: entity.firstName,
      lastName: entity.lastName,
      profilePicUrl: entity.profilePicUrl,
    );
  }
}
