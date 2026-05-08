import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class EventActivity extends Equatable {
  @JsonKey(name: 'activity_time')
  final DateTime activityTime;

  @JsonKey(name: 'activity_title')
  final String activityTitle;

  @JsonKey(name: 'description')
  final String description;

  const EventActivity({
    required this.activityTime,
    required this.activityTitle,
    this.description = '',
  });

  EventActivity copyWith({
    DateTime? activityTime,
    String? activityTitle,
    String? description,
  }) {
    return EventActivity(
      activityTime: activityTime ?? this.activityTime,
      activityTitle: activityTitle ?? this.activityTitle,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [activityTime, activityTitle, description];
}
