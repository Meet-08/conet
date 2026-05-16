import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_trend_by_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventGetRegistrationTrendByDate usecase;
  late MockEventRepository mockRepository;

  final tTrend = EventRegistrationTrend(
    totalRegistrations: 3,
    points: [
      EventRegistrationTrendPoint(date: DateTime(2026, 5, 1), count: 1),
      EventRegistrationTrendPoint(date: DateTime(2026, 5, 2), count: 2),
    ],
  );

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = EventGetRegistrationTrendByDate(repository: mockRepository);
  });

  group('EventGetRegistrationTrendByDate', () {
    test(
      'should call repository.getRegistrationTrendByDate and return trend',
      () async {
        when(
          () => mockRepository.getRegistrationTrendByDate(
            eventId: 'event-1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).thenAnswer((_) async => Right(tTrend));

        final result = await usecase(
          eventId: 'event-1',
          from: DateTime(2026, 5, 1),
          to: DateTime(2026, 5, 2),
        );

        expect(result.isRight(), true);
        result.fold((_) => fail('Expected Right'), (trend) {
          expect(trend.totalRegistrations, 3);
          expect(trend.points.length, 2);
        });

        verify(
          () => mockRepository.getRegistrationTrendByDate(
            eventId: 'event-1',
            from: any(named: 'from'),
            to: any(named: 'to'),
          ),
        ).called(1);
      },
    );

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.getRegistrationTrendByDate(
          eventId: 'event-1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Left(AppFailure('Trend failed')));

      final result = await usecase(
        eventId: 'event-1',
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 5, 2),
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Trend failed'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
