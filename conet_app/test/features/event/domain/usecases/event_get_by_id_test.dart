import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventGetById usecase;
  late MockEventRepository mockRepository;

  final tEvent = Event(
    id: 'event-1',
    organizerId: 'org-1',
    title: 'Flutter Meetup',
    category: 'Technology',
    eventDate: DateTime(2026, 4, 10),
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
    usecase = EventGetById(repository: mockRepository);
  });

  group('EventGetById', () {
    test('should call getEventById with the provided event id', () async {
      when(
        () => mockRepository.getEventById('event-1'),
      ).thenAnswer((_) async => Right(tEvent));

      await usecase('event-1');

      verify(() => mockRepository.getEventById('event-1')).called(1);
    });

    test('should return Right<Event> on success', () async {
      when(
        () => mockRepository.getEventById('event-1'),
      ).thenAnswer((_) async => Right(tEvent));

      final result = await usecase('event-1');

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (event) {
        expect(event.id, 'event-1');
        expect(event.title, 'Flutter Meetup');
      });
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.getEventById('event-1'),
      ).thenAnswer((_) async => Left(AppFailure('Event not found')));

      final result = await usecase('event-1');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Event not found'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
