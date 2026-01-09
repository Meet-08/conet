import 'package:conet_app/core/common/entities/user.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Conversation extends Equatable {
  final String id;

  @JsonKey(name: 'other_user')
  final User otherUser;

  const Conversation({required this.id, required this.otherUser});

  @override
  List<Object?> get props => [id, otherUser];
}
