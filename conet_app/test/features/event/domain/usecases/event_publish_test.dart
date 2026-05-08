import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventPublish usecase;
  late MockEventRepository mockRepository;

  final tPayload = EventCreatePayload(
    title: 'Flutter Meetup',
    category: 'Technology',
    startDate: DateTime(2026, 4, 10),
    endDate: DateTime(2026, 4, 10),
    startTime: DateTime(2026, 4, 10, 9),
    endTime: DateTime(2026, 4, 10, 12),
    locationType: 'OFFLINE',
    location: 'Campus Hall',
    ticketPriceType: 'FREE',
    maxParticipant: 100,
  );

  final tEvent = Event(
    id: 'event-1',
    organizerId: 'org-1',
    title: 'Flutter Meetup',
    category: 'Technology',
    startDate: DateTime(2026, 4, 10),
    endDate: DateTime(2026, 4, 10),
    startTime: DateTime(2026, 4, 10, 9),
    endTime: DateTime(2026, 4, 10, 12),
    locationType: 'OFFLINE',
    location: 'Campus Hall',
    ticketPriceType: 'FREE',
    maxParticipant: 100,
    eventStatus: 'PUBLISHED',
  );

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = EventPublish(repository: mockRepository);
  });

  group('EventPublish', () {
    test('should call publishEvent with payload', () async {
      when(
        () => mockRepository.publishEvent(tPayload),
      ).thenAnswer((_) async => Right(tEvent));

      await usecase(tPayload);

      verify(() => mockRepository.publishEvent(tPayload)).called(1);
    });

    test('should return Right<Event> on success', () async {
      when(
        () => mockRepository.publishEvent(tPayload),
      ).thenAnswer((_) async => Right(tEvent));

      final result = await usecase(tPayload);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (event) {
        expect(event.id, 'event-1');
        expect(event.eventStatus, 'PUBLISHED');
      });
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.publishEvent(tPayload),
      ).thenAnswer((_) async => Left(AppFailure('Publish failed')));

      final result = await usecase(tPayload);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Publish failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}

