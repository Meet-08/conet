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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Extract actor data from the nested join field
    final actor =
        json['users_notifications_actor_idTousers'] as Map<String, dynamic>?;

    return NotificationModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      receiverId: json['receiver_id'] as String,
      isSeen: json['is_seen'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String?,
      type: json['type'] as String,
      actorFirstName: actor?['first_name'] as String?,
      actorLastName: actor?['last_name'] as String?,
      actorUsername: actor?['username'] as String?,
      actorProfilePicUrl: actor?['profile_pic_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
