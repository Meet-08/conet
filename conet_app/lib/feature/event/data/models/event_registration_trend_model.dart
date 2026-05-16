import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';

class EventRegistrationTrendModel extends EventRegistrationTrend {
  const EventRegistrationTrendModel({
    required super.totalRegistrations,
    required super.points,
  });

  factory EventRegistrationTrendModel.fromJson(Map<String, dynamic> json) {
    final pointsRaw = (json['counts_by_date'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();

    return EventRegistrationTrendModel(
      totalRegistrations: (json['total_registrations'] as num?)?.toInt() ?? 0,
      points: pointsRaw
          .map((item) {
            final dateString = item['date']?.toString();
            if (dateString == null || dateString.isEmpty) return null;
            final date = DateTime.tryParse(dateString);
            if (date == null) return null;
            return EventRegistrationTrendPoint(
              date: date,
              count: (item['count'] as num?)?.toInt() ?? 0,
            );
          })
          .whereType<EventRegistrationTrendPoint>()
          .toList(growable: false),
    );
  }
}
