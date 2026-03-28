import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class EventCohost extends Equatable {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(defaultValue: '')
  final String username;

  @JsonKey(name: 'first_name')
  final String? firstName;

  @JsonKey(name: 'last_name')
  final String? lastName;

  @JsonKey(name: 'profile_pic_url')
  final String? profilePicUrl;

  const EventCohost({
    required this.id,
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicUrl,
  });

  String get displayName {
    final fullName = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ].join(' ');

    if (fullName.isNotEmpty) {
      return fullName;
    }
    if (username.trim().isNotEmpty) {
      return username;
    }
    return 'Unknown';
  }

  EventCohost copyWith({
    String? id,
    String? userId,
    String? username,
    String? firstName,
    String? lastName,
    String? profilePicUrl,
  }) {
    return EventCohost(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePicUrl: profilePicUrl ?? this.profilePicUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    username,
    firstName,
    lastName,
    profilePicUrl,
  ];
}
