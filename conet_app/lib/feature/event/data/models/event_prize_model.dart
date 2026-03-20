import 'package:conet_app/feature/event/domain/entities/event_prize.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_prize_model.g.dart';

@JsonSerializable()
class EventPrizeModel extends EventPrize {
  const EventPrizeModel({required super.position, required super.prize});

  factory EventPrizeModel.fromJson(Map<String, dynamic> json) =>
      _$EventPrizeModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventPrizeModelToJson(this);

  factory EventPrizeModel.fromEntity(EventPrize entity) {
    return EventPrizeModel(position: entity.position, prize: entity.prize);
  }
}
