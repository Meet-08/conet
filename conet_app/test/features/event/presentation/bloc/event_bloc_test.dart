import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/event/domain/entities/event.dart';
import 'package:conet_app/feature/event/domain/entities/event_create_payload.dart';
import 'package:conet_app/feature/event/domain/entities/event_list_item.dart';
import 'package:conet_app/feature/event/domain/entities/event_page.dart';
import 'package:conet_app/feature/event/domain/entities/event_register_response.dart';
import 'package:conet_app/feature/event/domain/entities/event_registration_payload.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_my_organized_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_get_published_events.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish.dart';
import 'package:conet_app/feature/event/domain/usecases/event_publish_by_id.dart';
import 'package:conet_app/feature/event/domain/usecases/event_register.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save.dart';
import 'package:conet_app/feature/event/domain/usecases/event_save_draft.dart';
import 'package:conet_app/feature/event/domain/usecases/event_setup_organizer_resources.dart';
import 'package:conet_app/feature/event/domain/usecases/event_update.dart';
import 'package:conet_app/feature/event/domain/usecases/event_update_draft.dart';
import 'package:conet_app/feature/event/presentation/bloc/event_bloc.dart';
import 'package:conet_app/feature/message/domain/usecases/message_create_group.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockEventGetById extends Mock implements EventGetById {}

class MockEventGetPublishedEvents extends Mock
    implements EventGetPublishedEvents {}

class MockEventGetMyEvents extends Mock implements EventGetMyEvents {}

class MockEventGetMyOrganizedEvents extends Mock
    implements EventGetMyOrganizedEvents {}

class MockEventPublishById extends Mock implements EventPublishById {}

class MockEventPublish extends Mock implements EventPublish {}

class MockEventRegister extends Mock implements EventRegister {}

class MockEventSave extends Mock implements EventSave {}

class MockEventSaveDraft extends Mock implements EventSaveDraft {}

class MockEventSetupOrganizerResources extends Mock
    implements EventSetupOrganizerResources {}

class MockMessageCreateGroup extends Mock implements MessageCreateGroup {}
class MockEventUpdate extends Mock implements EventUpdate {}
class MockEventUpdateDraft extends Mock implements EventUpdateDraft {}

void main() {
  late EventBloc bloc;
  late MockEventGetById mockGetById;
  late MockEventGetPublishedEvents mockGetPublishedEvents;
  late MockEventGetMyEvents mockGetMyEvents;
  late MockEventGetMyOrganizedEvents mockGetMyOrganizedEvents;
  late MockEventPublish mockPublish;
  late MockEventRegister mockRegister;
  late MockEventSave mockSave;
  late MockEventSaveDraft mockSaveDraft;
  late MockEventSetupOrganizerResources mockSetupOrganizerResources;
  late MockMessageCreateGroup mockCreateGroup;
  late MockEventUpdate mockUpdateEvent;
  late MockEventUpdateDraft mockUpdateDraft;

  final tEventListItem1 = EventListItem(
    id: 'event-1',
    title: 'Flutter Meetup',
    category: 'Technology',
    ticketPriceType: 'FREE',
    eventStartDate: DateTime(2026, 4, 10),
    venue: 'Campus Hall',
  );

  final tEventListItem2 = EventListItem(
    id: 'event-2',
    title: 'Design Sprint',
    category: 'Design',
    ticketPriceType: 'PAID',
    price: 10,
    eventStartDate: DateTime(2026, 4, 11),
    location: 'Online',
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

  const tRegistrationPayload = EventRegistrationPayload();

  final tFirstPage = EventPage(
    events: [tEventListItem1],
    nextCursor: 'cursor-2',
    hasMore: true,
    pageSize: 20,
  );

  final tSecondPage = EventPage(
    events: [tEventListItem2],
    nextCursor: null,
    hasMore: false,
    pageSize: 20,
  );

  setUp(() {
    mockGetById = MockEventGetById();
    mockGetPublishedEvents = MockEventGetPublishedEvents();
    mockGetMyEvents = MockEventGetMyEvents();
    mockGetMyOrganizedEvents = MockEventGetMyOrganizedEvents();
    mockPublish = MockEventPublish();
    mockRegister = MockEventRegister();
    mockSave = MockEventSave();
    mockSaveDraft = MockEventSaveDraft();
    mockSetupOrganizerResources = MockEventSetupOrganizerResources();
    mockCreateGroup = MockMessageCreateGroup();
    mockUpdateEvent = MockEventUpdate();
    mockUpdateDraft = MockEventUpdateDraft();

    bloc = EventBloc(
      getById: mockGetById,
      getPublishedEvents: mockGetPublishedEvents,
      getMyEvents: mockGetMyEvents,
      getMyOrganizedEvents: mockGetMyOrganizedEvents,
      publish: mockPublish,
      registerEvent: mockRegister,
      saveEvent: mockSave,
      saveDraft: mockSaveDraft,
      updateDraft: mockUpdateDraft,
      updateEvent: mockUpdateEvent,
      setupOrganizerResources: mockSetupOrganizerResources,
      createGroup: mockCreateGroup,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is EventInitial', () {
    expect(bloc.state, isA<EventInitial>());
  });

  group('EventFetchByIdEvent', () {
    blocTest<EventBloc, EventState>(
      'emits [EventDetailLoading, EventDetailLoaded] when usecase succeeds',
      build: () {
        when(
          () => mockGetById('event-1'),
        ).thenAnswer((_) async => Right(tEvent));
        return bloc;
      },
      act: (bloc) => bloc.add(const EventFetchByIdEvent('event-1')),
      expect: () => [
        isA<EventDetailLoading>(),
        isA<EventDetailLoaded>().having(
          (s) => s.event.id,
          'event.id',
          'event-1',
        ),
      ],
      verify: (_) {
        verify(() => mockGetById('event-1')).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [EventDetailLoading, EventDetailFailure] when usecase fails',
      build: () {
        when(
          () => mockGetById('event-1'),
        ).thenAnswer((_) async => Left(AppFailure('Event not found')));
        return bloc;
      },
      act: (bloc) => bloc.add(const EventFetchByIdEvent('event-1')),
      expect: () => [
        isA<EventDetailLoading>(),
        isA<EventDetailFailure>().having(
          (s) => s.message,
          'message',
          'Event not found',
        ),
      ],
    );
  });

  group('EventFetchPublishedEventsEvent', () {
    final dateFrom = DateTime(2026, 4, 1);
    final dateTo = DateTime(2026, 4, 30);

    blocTest<EventBloc, EventState>(
      'emits [EventLoading, EventLoaded] with the first page and stores cursor',
      build: () {
        when(
          () => mockGetPublishedEvents(
            cursor: null,
            category: 'Technology',
            locationType: 'OFFLINE',
            dateFrom: dateFrom,
            dateTo: dateTo,
            search: 'flutter',
          ),
        ).thenAnswer((_) async => Right(tFirstPage));
        return bloc;
      },
      act: (bloc) => bloc.add(
        EventFetchPublishedEventsEvent(
          category: 'Technology',
          locationType: 'OFFLINE',
          dateFrom: dateFrom,
          dateTo: dateTo,
          search: 'flutter',
        ),
      ),
      expect: () => [
        isA<EventLoading>(),
        isA<EventLoaded>()
            .having((s) => s.events.length, 'events.length', 1)
            .having((s) => s.nextCursor, 'nextCursor', 'cursor-2')
            .having((s) => s.hasMore, 'hasMore', true),
      ],
      verify: (_) {
        verify(
          () => mockGetPublishedEvents(
            cursor: null,
            category: 'Technology',
            locationType: 'OFFLINE',
            dateFrom: dateFrom,
            dateTo: dateTo,
            search: 'flutter',
          ),
        ).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [EventLoading, EventFailure] when first page fetch fails',
      build: () {
        when(
          () => mockGetPublishedEvents(
            cursor: null,
            category: null,
            locationType: null,
            dateFrom: null,
            dateTo: null,
            search: null,
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to load events')));
        return bloc;
      },
      act: (bloc) => bloc.add(const EventFetchPublishedEventsEvent()),
      expect: () => [
        isA<EventLoading>(),
        isA<EventFailure>().having(
          (s) => s.message,
          'message',
          'Failed to load events',
        ),
      ],
    );

    blocTest<EventBloc, EventState>(
      'appends second page when EventFetchMorePublishedEventsEvent is added',
      build: () {
        when(
          () => mockGetPublishedEvents(
            cursor: null,
            category: null,
            locationType: null,
            dateFrom: null,
            dateTo: null,
            search: null,
          ),
        ).thenAnswer((_) async => Right(tFirstPage));
        when(
          () => mockGetPublishedEvents(cursor: 'cursor-2'),
        ).thenAnswer((_) async => Right(tSecondPage));
        return bloc;
      },
      act: (bloc) {
        bloc
          ..add(const EventFetchPublishedEventsEvent())
          ..add(const EventFetchMorePublishedEventsEvent());
      },
      expect: () => [
        isA<EventLoading>(),
        isA<EventLoaded>()
            .having((s) => s.events.length, 'events.length', 1)
            .having((s) => s.hasMore, 'hasMore', true),
        isA<EventLoaded>()
            .having((s) => s.events.length, 'events.length', 2)
            .having((s) => s.nextCursor, 'nextCursor', 'cursor-2')
            .having((s) => s.hasMore, 'hasMore', false),
      ],
      verify: (_) {
        verify(() => mockGetPublishedEvents(cursor: 'cursor-2')).called(1);
      },
    );
  });

  group('EventFetchMyEventsEvent', () {
    final myFirstPage = EventPage(
      events: [tEventListItem1],
      nextCursor: 'my-cursor-2',
      hasMore: true,
      pageSize: 10,
    );

    final mySecondPage = EventPage(
      events: [tEventListItem2],
      nextCursor: null,
      hasMore: false,
      pageSize: 10,
    );

    blocTest<EventBloc, EventState>(
      'loads and paginates my events using remembered type and page size',
      build: () {
        when(
          () => mockGetMyEvents(type: 'upcoming', cursor: null, limit: 10),
        ).thenAnswer((_) async => Right(myFirstPage));

        when(
          () => mockGetMyEvents(
            type: 'upcoming',
            cursor: 'my-cursor-2',
            limit: 10,
          ),
        ).thenAnswer((_) async => Right(mySecondPage));

        return bloc;
      },
      act: (bloc) {
        bloc
          ..add(const EventFetchMyEventsEvent(type: 'upcoming', limit: 10))
          ..add(const EventFetchMoreMyEventsEvent());
      },
      expect: () => [
        isA<MyEventsLoading>(),
        isA<MyEventsLoaded>()
            .having((s) => s.type, 'type', 'upcoming')
            .having((s) => s.events.length, 'events.length', 1)
            .having((s) => s.hasMore, 'hasMore', true)
            .having((s) => s.pageSize, 'pageSize', 10),
        isA<MyEventsLoaded>()
            .having((s) => s.events.length, 'events.length', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
      verify: (_) {
        verify(
          () => mockGetMyEvents(
            type: 'upcoming',
            cursor: 'my-cursor-2',
            limit: 10,
          ),
        ).called(1);
      },
    );
  });

  group('EventPublishEvent', () {
    blocTest<EventBloc, EventState>(
      'emits [EventCreateLoading, EventCreateSuccess(isDraft: false)] on success',
      build: () {
        when(
          () => mockPublish(tPayload),
        ).thenAnswer((_) async => Right(tEvent));
        return bloc;
      },
      act: (bloc) => bloc.add(EventPublishEvent(tPayload)),
      expect: () => [
        isA<EventCreateLoading>(),
        isA<EventCreateSuccess>()
            .having((s) => s.event.id, 'event.id', 'event-1')
            .having((s) => s.isDraft, 'isDraft', false),
      ],
      verify: (_) {
        verify(() => mockPublish(tPayload)).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [EventCreateLoading, EventCreateFailure] on failure',
      build: () {
        when(
          () => mockPublish(tPayload),
        ).thenAnswer((_) async => Left(AppFailure('Publish failed')));
        return bloc;
      },
      act: (bloc) => bloc.add(EventPublishEvent(tPayload)),
      expect: () => [
        isA<EventCreateLoading>(),
        isA<EventCreateFailure>().having(
          (s) => s.message,
          'message',
          'Publish failed',
        ),
      ],
    );
  });

  group('EventFetchMyOrganizedEventsEvent', () {
    final organizedFirstPage = EventPage(
      events: [tEventListItem1],
      nextCursor: 'org-cursor-2',
      hasMore: true,
      pageSize: 10,
    );
    final organizedSecondPage = EventPage(
      events: [tEventListItem2],
      nextCursor: null,
      hasMore: false,
      pageSize: 10,
    );
    final dateFrom = DateTime(2026, 4, 12);

    blocTest<EventBloc, EventState>(
      'loads and paginates organized events using DB level filter arguments',
      build: () {
        when(
          () => mockGetMyOrganizedEvents(
            status: 'published',
            timeline: 'upcoming',
            dateFrom: dateFrom,
            dateTo: null,
            cursor: null,
            limit: 10,
          ),
        ).thenAnswer((_) async => Right(organizedFirstPage));

        when(
          () => mockGetMyOrganizedEvents(
            status: 'published',
            timeline: 'upcoming',
            dateFrom: dateFrom,
            dateTo: null,
            cursor: 'org-cursor-2',
            limit: 10,
          ),
        ).thenAnswer((_) async => Right(organizedSecondPage));

        return bloc;
      },
      act: (bloc) {
        bloc
          ..add(
            EventFetchMyOrganizedEventsEvent(
              status: 'published',
              timeline: 'upcoming',
              dateFrom: dateFrom,
              limit: 10,
            ),
          )
          ..add(const EventFetchMoreMyOrganizedEventsEvent());
      },
      expect: () => [
        isA<MyOrganizedEventsLoading>(),
        isA<MyOrganizedEventsLoaded>()
            .having((s) => s.status, 'status', 'published')
            .having((s) => s.events.length, 'events.length', 1)
            .having((s) => s.hasMore, 'hasMore', true)
            .having((s) => s.pageSize, 'pageSize', 10),
        isA<MyOrganizedEventsLoaded>()
            .having((s) => s.events.length, 'events.length', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
      verify: (_) {
        verify(
          () => mockGetMyOrganizedEvents(
            status: 'published',
            timeline: 'upcoming',
            dateFrom: dateFrom,
            dateTo: null,
            cursor: 'org-cursor-2',
            limit: 10,
          ),
        ).called(1);
      },
    );
  });

  group('EventSaveDraftEvent', () {
    blocTest<EventBloc, EventState>(
      'emits [EventCreateLoading, EventCreateSuccess(isDraft: true)] on success',
      build: () {
        when(
          () => mockSaveDraft(tPayload),
        ).thenAnswer((_) async => Right(tEvent));
        return bloc;
      },
      act: (bloc) => bloc.add(EventSaveDraftEvent(tPayload)),
      expect: () => [
        isA<EventCreateLoading>(),
        isA<EventCreateSuccess>()
            .having((s) => s.event.id, 'event.id', 'event-1')
            .having((s) => s.isDraft, 'isDraft', true),
      ],
      verify: (_) {
        verify(() => mockSaveDraft(tPayload)).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'updates draft when eventId is provided',
      build: () {
        when(
          () => mockUpdateDraft('event-1', tPayload),
        ).thenAnswer((_) async => Right(tEvent));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(EventSaveDraftEvent(tPayload, eventId: 'event-1')),
      expect: () => [
        isA<EventCreateLoading>(),
        isA<EventCreateSuccess>()
            .having((s) => s.event.id, 'event.id', 'event-1')
            .having((s) => s.isDraft, 'isDraft', true),
      ],
      verify: (_) {
        verify(() => mockUpdateDraft('event-1', tPayload)).called(1);
        verifyNever(() => mockSaveDraft(tPayload));
      },
    );
  });

  group('EventRegisterEvent', () {
    blocTest<EventBloc, EventState>(
      'emits [EventRegistrationLoading, EventRegistrationSuccess] on success',
      build: () {
        when(() => mockRegister('event-1', tRegistrationPayload)).thenAnswer(
          (_) async => Right(
            EventRegisterResponse(event: tEvent, registrationId: 'reg-1'),
          ),
        );
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const EventRegisterEvent('event-1', tRegistrationPayload)),
      expect: () => [
        isA<EventRegistrationLoading>(),
        isA<EventRegistrationSuccess>().having(
          (s) => s.response.event.id,
          'event.id',
          'event-1',
        ),
      ],
      verify: (_) {
        verify(() => mockRegister('event-1', tRegistrationPayload)).called(1);
      },
    );

    blocTest<EventBloc, EventState>(
      'emits [EventRegistrationLoading, EventRegistrationFailure] on failure',
      build: () {
        when(
          () => mockRegister('event-1', tRegistrationPayload),
        ).thenAnswer((_) async => Left(AppFailure('Registration failed')));
        return bloc;
      },
      act: (bloc) =>
          bloc.add(const EventRegisterEvent('event-1', tRegistrationPayload)),
      expect: () => [
        isA<EventRegistrationLoading>(),
        isA<EventRegistrationFailure>().having(
          (s) => s.message,
          'message',
          'Registration failed',
        ),
      ],
    );
  });
}

