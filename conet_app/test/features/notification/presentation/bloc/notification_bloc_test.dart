import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/notification/domain/entities/notification.dart'
    as app_notification;
import 'package:conet_app/feature/notification/domain/entities/notification_page.dart';
import 'package:conet_app/feature/notification/domain/usecases/get_notifications_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/mark_all_as_seen_usecase.dart';
import 'package:conet_app/feature/notification/domain/usecases/watch_notifications_usecase.dart';
import 'package:conet_app/feature/notification/presentation/bloc/notification_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockMarkAllAsSeenUseCase extends Mock implements MarkAllAsSeenUseCase {}

class MockWatchNotificationsUseCase extends Mock
    implements WatchNotificationsUseCase {}

void main() {
  late NotificationBloc bloc;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockMarkAllAsSeenUseCase mockMarkAllAsSeen;
  late MockWatchNotificationsUseCase mockWatchNotifications;

  final tNotification1 = app_notification.Notification(
    id: 'n1',
    actorId: 'actor-1',
    receiverId: 'receiver-1',
    isSeen: false,
    createdAt: DateTime(2026, 2, 24, 12),
    content: 'Alice liked your post',
    type: 'POST_LIKE',
    actorFirstName: 'Alice',
    actorLastName: 'Smith',
    actorUsername: 'alice',
  );

  final tNotification2 = app_notification.Notification(
    id: 'n2',
    actorId: 'actor-2',
    receiverId: 'receiver-1',
    isSeen: false,
    createdAt: DateTime(2026, 2, 24, 13),
    content: 'Bob commented on your post',
    type: 'POST_COMMENT',
    actorFirstName: 'Bob',
    actorLastName: 'Jones',
    actorUsername: 'bob',
  );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ0ZXN0LXVzZXIiLCJyb2xlIjoiYW5vbiIsImV4cCI6NDA3MDkwODgwMH0.hQoymI6cbh0JX3w9cU5PjJYAmYhKCYwiVdc0GqORdzA',
    );
  });

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockMarkAllAsSeen = MockMarkAllAsSeenUseCase();
    mockWatchNotifications = MockWatchNotificationsUseCase();

    when(
      () => mockGetNotifications(
        limit: any(named: 'limit'),
        cursor: any(named: 'cursor'),
      ),
    ).thenAnswer(
      (_) async =>
          const Right(NotificationPage(notifications: [], unseenCount: 0)),
    );
    when(() => mockMarkAllAsSeen()).thenAnswer((_) async => const Right(unit));
    when(
      () => mockWatchNotifications(any()),
    ).thenAnswer((_) => const Stream.empty());

    bloc = NotificationBloc(
      getNotifications: mockGetNotifications,
      markAllAsSeen: mockMarkAllAsSeen,
      watchNotifications: mockWatchNotifications,
    );
  });

  tearDown(() async {
    await bloc.close();
  });

  test('initial state is NotificationState with defaults', () {
    expect(bloc.state.notifications, isEmpty);
    expect(bloc.state.unseenCount, 0);
    expect(bloc.state.isLoading, false);
    expect(bloc.state.isFetchingMore, false);
    expect(bloc.state.hasReachedEnd, false);
    expect(bloc.state.error, isNull);
  });

  group('NotificationLoadEvent', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits loading then loaded state on success',
      build: () {
        when(
          () => mockGetNotifications(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer(
          (_) async => Right(
            NotificationPage(
              notifications: [tNotification1],
              unseenCount: 1,
              nextCursor: 'n1',
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadEvent()),
      expect: () => [
        isA<NotificationState>()
            .having((s) => s.isLoading, 'isLoading', true)
            .having((s) => s.error, 'error', isNull),
        isA<NotificationState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.notifications, 'notifications', [tNotification1])
            .having((s) => s.unseenCount, 'unseenCount', 1)
            .having((s) => s.hasReachedEnd, 'hasReachedEnd', false),
      ],
      verify: (_) {
        verify(() => mockGetNotifications(limit: 20, cursor: null)).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits loading then error state on failure',
      build: () {
        when(
          () => mockGetNotifications(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to load')));
        return bloc;
      },
      act: (bloc) => bloc.add(const NotificationLoadEvent()),
      expect: () => [
        isA<NotificationState>().having((s) => s.isLoading, 'isLoading', true),
        isA<NotificationState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.error?.message, 'error', 'Failed to load'),
      ],
    );
  });

  group('NotificationLoadMoreEvent', () {
    blocTest<NotificationBloc, NotificationState>(
      'appends next page notifications on success',
      build: () {
        when(() => mockGetNotifications(limit: 20, cursor: null)).thenAnswer(
          (_) async => Right(
            NotificationPage(
              notifications: [tNotification1],
              unseenCount: 1,
              nextCursor: 'n1',
            ),
          ),
        );
        when(() => mockGetNotifications(limit: 20, cursor: 'n1')).thenAnswer(
          (_) async => Right(
            NotificationPage(
              notifications: [tNotification2],
              unseenCount: 1,
              nextCursor: null,
            ),
          ),
        );
        return bloc;
      },
      act: (bloc) async {
        bloc.add(const NotificationLoadEvent());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const NotificationLoadMoreEvent());
      },
      expect: () => [
        isA<NotificationState>().having((s) => s.isLoading, 'isLoading', true),
        isA<NotificationState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.notifications, 'notifications', [tNotification1]),
        isA<NotificationState>().having(
          (s) => s.isFetchingMore,
          'isFetchingMore',
          true,
        ),
        isA<NotificationState>()
            .having((s) => s.isFetchingMore, 'isFetchingMore', false)
            .having((s) => s.notifications, 'notifications', [
              tNotification1,
              tNotification2,
            ])
            .having((s) => s.hasReachedEnd, 'hasReachedEnd', true),
      ],
    );
  });

  group('NotificationMarkAllSeenEvent', () {
    blocTest<NotificationBloc, NotificationState>(
      'optimistically marks all as seen and keeps state on success',
      build: () => bloc,
      seed: () => NotificationState(
        notifications: [tNotification1, tNotification2],
        unseenCount: 2,
      ),
      act: (bloc) => bloc.add(const NotificationMarkAllSeenEvent()),
      expect: () => [
        isA<NotificationState>()
            .having((s) => s.unseenCount, 'unseenCount', 0)
            .having(
              (s) => s.notifications.every((n) => n.isSeen),
              'allSeen',
              true,
            ),
      ],
      verify: (_) {
        verify(() => mockMarkAllAsSeen()).called(1);
      },
    );

    blocTest<NotificationBloc, NotificationState>(
      'rolls back unseen count and sets error when markAllAsSeen fails',
      build: () {
        when(
          () => mockMarkAllAsSeen(),
        ).thenAnswer((_) async => Left(AppFailure('Failed to mark')));
        return bloc;
      },
      seed: () =>
          NotificationState(notifications: [tNotification1], unseenCount: 1),
      act: (bloc) => bloc.add(const NotificationMarkAllSeenEvent()),
      expect: () => [
        isA<NotificationState>().having((s) => s.unseenCount, 'unseenCount', 0),
        isA<NotificationState>()
            .having((s) => s.unseenCount, 'unseenCount', 1)
            .having((s) => s.error?.message, 'error', 'Failed to mark'),
      ],
    );
  });

  group('NotificationRealtimeReceivedEvent', () {
    blocTest<NotificationBloc, NotificationState>(
      'refreshes first page silently and updates state',
      build: () {
        when(
          () => mockGetNotifications(
            limit: any(named: 'limit'),
            cursor: any(named: 'cursor'),
          ),
        ).thenAnswer(
          (_) async => Right(
            NotificationPage(
              notifications: [tNotification2],
              unseenCount: 4,
              nextCursor: null,
            ),
          ),
        );
        return bloc;
      },
      seed: () =>
          NotificationState(notifications: [tNotification1], unseenCount: 1),
      act: (bloc) => bloc.add(const NotificationRealtimeReceivedEvent()),
      expect: () => [
        isA<NotificationState>()
            .having((s) => s.notifications, 'notifications', [tNotification2])
            .having((s) => s.unseenCount, 'unseenCount', 4)
            .having((s) => s.hasReachedEnd, 'hasReachedEnd', true),
      ],
      verify: (_) {
        verify(() => mockGetNotifications(limit: 20, cursor: null)).called(1);
      },
    );
  });
}
