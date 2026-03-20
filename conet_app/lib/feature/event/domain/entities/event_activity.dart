import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class EventActivity extends Equatable {
  @JsonKey(name: 'activity_time')
  final DateTime activityTime;

  @JsonKey(name: 'activity_title')
  final String activityTitle;

  const EventActivity({
    required this.activityTime,
    required this.activityTitle,
  });

  EventActivity copyWith({DateTime? activityTime, String? activityTitle}) {
    return EventActivity(
      activityTime: activityTime ?? this.activityTime,
      activityTitle: activityTitle ?? this.activityTitle,
    );
  }

  @override
  List<Object?> get props => [activityTime, activityTitle];
}
