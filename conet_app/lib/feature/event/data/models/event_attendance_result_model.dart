import 'package:conet_app/feature/event/domain/entities/event_attendance_result.dart';

class EventAttendanceResultModel extends EventAttendanceResult {
  const EventAttendanceResultModel({
    required super.success,
    required super.message,
  });

  factory EventAttendanceResultModel.fromJson(Map<String, dynamic> json) {
    return EventAttendanceResultModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? 'Unknown response',
    );
  }
}
