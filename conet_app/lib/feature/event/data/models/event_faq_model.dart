import 'package:conet_app/feature/event/domain/entities/event_faq.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_faq_model.g.dart';

@JsonSerializable()
class EventFaqModel extends EventFaq {
  const EventFaqModel({required super.question, required super.answer});

  factory EventFaqModel.fromJson(Map<String, dynamic> json) =>
      _$EventFaqModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventFaqModelToJson(this);

  factory EventFaqModel.fromEntity(EventFaq entity) {
    return EventFaqModel(question: entity.question, answer: entity.answer);
  }
}
