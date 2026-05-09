import 'package:conet_app/feature/event/data/models/event_create_payload_model.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('EventCreatePayloadModel.toJson includes instructions', () {
    final payload = EventCreatePayload(
      title: 'Flutter Meetup',
      category: 'Technology',
      instructions: '  Bring your college ID  ',
      startDate: DateTime(2026, 4, 10),
      endDate: DateTime(2026, 4, 10),
      startTime: DateTime(2026, 4, 10, 9),
      endTime: DateTime(2026, 4, 10, 12),
      locationType: 'OFFLINE',
      location: 'Campus Hall',
      ticketPriceType: 'FREE',
    );

    final model = EventCreatePayloadModel.fromEntity(payload, publish: false);
    final json = model.toJson();

    expect(json['instructions'], 'Bring your college ID');
  });
}
