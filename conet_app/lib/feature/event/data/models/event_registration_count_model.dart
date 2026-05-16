import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';

class EventRegistrationCountModel extends EventRegistrationCount {
  const EventRegistrationCountModel({
    required super.label,
    required super.count,
  });

  static List<EventRegistrationCountModel> fromJsonList(
    List<dynamic> json,
    String labelKey,
  ) {
    return json
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => EventRegistrationCountModel(
            label: item[labelKey]?.toString().trim() ?? '',
            count: (item['count'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((item) => item.label.isNotEmpty)
        .toList(growable: false);
  }
}
