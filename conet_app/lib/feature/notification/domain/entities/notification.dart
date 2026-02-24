import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Notification extends Equatable {
  final String id;

  @JsonKey(name: 'actor_id')
  final String actorId;

  @JsonKey(name: 'receiver_id')
  final String receiverId;

  @JsonKey(name: 'is_seen')
  final bool isSeen;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  final String? content;
  final String type;

  // Actor profile fields (joined from backend)
  final String? actorFirstName;
  final String? actorLastName;
  final String? actorUsername;
  final String? actorProfilePicUrl;

  const Notification({
    required this.id,
    required this.actorId,
    required this.receiverId,
    required this.isSeen,
    required this.createdAt,
    this.content,
    required this.type,
    this.actorFirstName,
    this.actorLastName,
    this.actorUsername,
    this.actorProfilePicUrl,
  });

  String get actorDisplayName {
    if (actorFirstName != null && actorLastName != null) {
      return '$actorFirstName $actorLastName';
    }
    return actorUsername ?? 'Someone';
  }

  Notification copyWith({bool? isSeen}) {
    return Notification(
      id: id,
      actorId: actorId,
      receiverId: receiverId,
      isSeen: isSeen ?? this.isSeen,
      createdAt: createdAt,
      content: content,
      type: type,
      actorFirstName: actorFirstName,
      actorLastName: actorLastName,
      actorUsername: actorUsername,
      actorProfilePicUrl: actorProfilePicUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    actorId,
    receiverId,
    isSeen,
    createdAt,
    content,
    type,
    actorFirstName,
    actorLastName,
    actorUsername,
    actorProfilePicUrl,
  ];
}
