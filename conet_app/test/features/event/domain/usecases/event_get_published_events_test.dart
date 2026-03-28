import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/repositories/event_repository.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_published_events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  late EventGetPublishedEvents usecase;
  late MockEventRepository mockRepository;

  final tPage = EventPage(
    events: [
      EventListItem(
        id: 'event-1',
        title: 'Flutter Meetup',
        category: 'Technology',
        ticketPriceType: 'FREE',
        eventStartDate: DateTime(2026, 4, 10),
      ),
    ],
    nextCursor: 'cursor-2',
    hasMore: true,
    pageSize: 20,
  );

  setUp(() {
    mockRepository = MockEventRepository();
    usecase = EventGetPublishedEvents(repository: mockRepository);
  });

  group('EventGetPublishedEvents', () {
    final dateFrom = DateTime(2026, 4, 1);
    final dateTo = DateTime(2026, 4, 30);

    test('should forward filters and pagination to repository', () async {
      when(
        () => mockRepository.getPublishedEvents(
          limit: 10,
          cursor: 'cursor-1',
          category: 'Technology',
          locationType: 'OFFLINE',
          dateFrom: dateFrom,
          dateTo: dateTo,
          search: 'flutter',
        ),
      ).thenAnswer((_) async => Right(tPage));

      await usecase(
        limit: 10,
        cursor: 'cursor-1',
        category: 'Technology',
        locationType: 'OFFLINE',
        dateFrom: dateFrom,
        dateTo: dateTo,
        search: 'flutter',
      );

      verify(
        () => mockRepository.getPublishedEvents(
          limit: 10,
          cursor: 'cursor-1',
          category: 'Technology',
          locationType: 'OFFLINE',
          dateFrom: dateFrom,
          dateTo: dateTo,
          search: 'flutter',
        ),
      ).called(1);
    });

    test('should return Right<EventPage> on success', () async {
      when(
        () => mockRepository.getPublishedEvents(
          limit: 20,
          cursor: null,
          category: null,
          locationType: null,
          dateFrom: null,
          dateTo: null,
          search: null,
        ),
      ).thenAnswer((_) async => Right(tPage));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (page) {
        expect(page.events.length, 1);
        expect(page.nextCursor, 'cursor-2');
        expect(page.hasMore, true);
      });
    });

    test('should return Left<AppFailure> on failure', () async {
      when(
        () => mockRepository.getPublishedEvents(
          limit: 20,
          cursor: null,
          category: null,
          locationType: null,
          dateFrom: null,
          dateTo: null,
          search: null,
        ),
      ).thenAnswer((_) async => Left(AppFailure('Failed to fetch events')));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch events'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
