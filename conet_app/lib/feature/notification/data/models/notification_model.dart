import 'package:conet_app/feature/notification/domain/entities/notification.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel extends Notification {
  const NotificationModel({
    required super.id,
    required super.actorId,
    required super.receiverId,
    required super.isSeen,
    required super.createdAt,
    super.content,
    required super.type,
    super.actorFirstName,
    super.actorLastName,
    super.actorUsername,
    super.actorProfilePicUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
