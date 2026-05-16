import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_attendees.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_count.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_trend.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_attendees.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_college.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_count_by_course.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_registration_trend_by_date.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_analytics_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventGetById extends Mock implements EventGetById {}

class MockEventGetAttendees extends Mock implements EventGetAttendees {}

class MockEventGetRegistrationTrendByDate extends Mock
    implements EventGetRegistrationTrendByDate {}

class MockEventGetRegistrationCountByCollege extends Mock
    implements EventGetRegistrationCountByCollege {}

class MockEventGetRegistrationCountByCourse extends Mock
    implements EventGetRegistrationCountByCourse {}

void main() {
  late EventAnalyticsBloc bloc;
  late MockEventGetById mockGetById;
  late MockEventGetAttendees mockGetAttendees;
  late MockEventGetRegistrationTrendByDate mockGetTrend;
  late MockEventGetRegistrationCountByCollege mockCollegeCounts;
  late MockEventGetRegistrationCountByCourse mockCourseCounts;

  final tEvent = Event(
    id: 'event-1',
    organizerId: 'org-1',
    title: 'Analytics Event',
    category: 'Tech',
    startDate: DateTime(2026, 5, 1),
    endDate: DateTime(2026, 5, 1),
    startTime: DateTime(2026, 5, 1, 9),
    endTime: DateTime(2026, 5, 1, 12),
    locationType: 'OFFLINE',
    location: 'Hall',
    ticketPriceType: 'FREE',
    maxParticipant: 50,
    eventStatus: 'PUBLISHED',
  );

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

  final tTrend = EventRegistrationTrend(
    totalRegistrations: 1,
    points: [EventRegistrationTrendPoint(date: DateTime(2026, 5, 1), count: 1)],
  );

  final tCollegeCounts = [
    const EventRegistrationCount(label: 'Engineering', count: 5),
  ];

  final tCourseCounts = [const EventRegistrationCount(label: 'CS', count: 4)];

  setUp(() {
    mockGetById = MockEventGetById();
    mockGetAttendees = MockEventGetAttendees();
    mockGetTrend = MockEventGetRegistrationTrendByDate();
    mockCollegeCounts = MockEventGetRegistrationCountByCollege();
    mockCourseCounts = MockEventGetRegistrationCountByCourse();

    bloc = EventAnalyticsBloc(
      getById: mockGetById,
      getAttendees: mockGetAttendees,
      getTrendByDate: mockGetTrend,
      getCollegeCounts: mockCollegeCounts,
      getCourseCounts: mockCourseCounts,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is EventAnalyticsInitial', () {
    expect(bloc.state, isA<EventAnalyticsInitial>());
  });

  blocTest<EventAnalyticsBloc, EventAnalyticsState>(
    'emits [Loading, Loaded] when all usecases succeed',
    build: () {
      when(() => mockGetById('event-1')).thenAnswer((_) async => Right(tEvent));
      when(
        () => mockGetAttendees(eventId: 'event-1', status: 'all'),
      ).thenAnswer((_) async => const Right(tAttendees));
      when(
        () => mockGetTrend(
          eventId: 'event-1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right(tTrend));
      when(
        () => mockCollegeCounts('event-1'),
      ).thenAnswer((_) async => Right(tCollegeCounts));
      when(
        () => mockCourseCounts('event-1'),
      ).thenAnswer((_) async => Right(tCourseCounts));

      return bloc;
    },
    act: (bloc) =>
        bloc.add(const EventAnalyticsLoadRequested(eventId: 'event-1')),
    expect: () => [isA<EventAnalyticsLoading>(), isA<EventAnalyticsLoaded>()],
    verify: (_) {
      verify(() => mockGetById('event-1')).called(1);
      verify(
        () => mockGetAttendees(eventId: 'event-1', status: 'all'),
      ).called(1);
      verify(
        () => mockGetTrend(
          eventId: 'event-1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
      verify(() => mockCollegeCounts('event-1')).called(1);
      verify(() => mockCourseCounts('event-1')).called(1);
    },
  );

  blocTest<EventAnalyticsBloc, EventAnalyticsState>(
    'emits [Loading, Failure] when a usecase fails',
    build: () {
      when(
        () => mockGetById('event-1'),
      ).thenAnswer((_) async => Left(AppFailure('Not found')));
      // stub other usecases so their calls return Futures (not null)
      when(
        () => mockGetAttendees(eventId: 'event-1', status: 'all'),
      ).thenAnswer((_) async => const Right(tAttendees));
      when(
        () => mockGetTrend(
          eventId: 'event-1',
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => Right(tTrend));
      when(
        () => mockCollegeCounts('event-1'),
      ).thenAnswer((_) async => Right(tCollegeCounts));
      when(
        () => mockCourseCounts('event-1'),
      ).thenAnswer((_) async => Right(tCourseCounts));

      return bloc;
    },
    act: (bloc) =>
        bloc.add(const EventAnalyticsLoadRequested(eventId: 'event-1')),
    expect: () => [
      isA<EventAnalyticsLoading>(),
      isA<EventAnalyticsFailure>().having(
        (s) => s.message,
        'message',
        'Not found',
      ),
    ],
  );
}
