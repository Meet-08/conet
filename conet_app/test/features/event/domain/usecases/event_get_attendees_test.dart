import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_attendees.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventGetAttendees usecase;
  late MockEventRepository mockRepository;

  const tAttendees = EventAttendees(
    eventId: 'event-1',
    participationType: 'individual',
    attendees: [
      EventAttendee(
        registrationId: 'reg-1',
        registrationStatus: 'registered',
        registeredAt: null,
        userId: 'user-1',
        user: EventAttendeeUser(id: 'user-1', username: 'demo'),
      ),
    ],
    summary: EventAttendeesSummary(totalAttendees: 1, registered: 1),
  );

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = EventGetAttendees(repository: mockRepository);
  });

  group('EventGetAttendees', () {
    test(
      'should call repository.getEventAttendees with provided params',
      () async {
        when(
          () => mockRepository.getEventAttendees(
            eventId: 'event-1',
            status: 'all',
          ),
        ).thenAnswer((_) async => const Right(tAttendees));

        await usecase(eventId: 'event-1', status: 'all');

        verify(
          () => mockRepository.getEventAttendees(
            eventId: 'event-1',
            status: 'all',
          ),
        ).called(1);
      },
    );

    test('should return Right<EventAttendees> on success', () async {
      when(
        () =>
            mockRepository.getEventAttendees(eventId: 'event-1', status: 'all'),
      ).thenAnswer((_) async => const Right(tAttendees));

      final result = await usecase(eventId: 'event-1', status: 'all');

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (att) {
        expect(att.eventId, 'event-1');
        expect(att.summary.totalAttendees, 1);
      });
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () =>
            mockRepository.getEventAttendees(eventId: 'event-1', status: 'all'),
      ).thenAnswer((_) async => Left(AppFailure('Failed')));

      final result = await usecase(eventId: 'event-1', status: 'all');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
