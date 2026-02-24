import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_data_source.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_realtime_data_source.dart';
import 'package:conet_app/feature/notification/data/models/notification_model.dart';
import 'package:conet_app/feature/notification/data/models/notification_page_model.dart';
import 'package:conet_app/feature/notification/data/repositories/notification_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationDataSource extends Mock
    implements NotificationDataSource {}

class MockNotificationRealtimeDataSource extends Mock
    implements NotificationRealtimeDataSource {}

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationDataSource mockDataSource;
  late MockNotificationRealtimeDataSource mockRealtimeDataSource;

  setUp(() {
    mockDataSource = MockNotificationDataSource();
    mockRealtimeDataSource = MockNotificationRealtimeDataSource();
    repository = NotificationRepositoryImpl(
      dataSource: mockDataSource,
      realtimeDataSource: mockRealtimeDataSource,
    );
  });

  final tNotificationModel = NotificationModel(
    id: 'notification-1',
    actorId: 'actor-1',
    receiverId: 'receiver-1',
    isSeen: false,
    createdAt: DateTime(2026, 2, 24),
    content: 'Alice liked your post',
    type: 'POST_LIKE',
    actorFirstName: 'Alice',
    actorLastName: 'Smith',
    actorUsername: 'alice',
    actorProfilePicUrl: 'https://example.com/avatar.png',
  );

  group('getNotifications', () {
    test('returns Right<NotificationPage> on success', () async {
      final tModel = NotificationPageModel(
        notifications: [tNotificationModel],
        unseenCount: 3,
        nextCursor: 'notification-1',
      );

      when(
        () => mockDataSource.getNotifications(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => tModel);

      final result = await repository.getNotifications(limit: 20);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (page) {
        expect(page.notifications.length, 1);
        expect(page.unseenCount, 3);
        expect(page.nextCursor, 'notification-1');
      });
      verify(
        () => mockDataSource.getNotifications(limit: 20, cursor: null),
      ).called(1);
    });

    test('returns Left with ServerException message', () async {
      when(
        () => mockDataSource.getNotifications(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenThrow(ServerException('Failed to fetch notifications'));

      final result = await repository.getNotifications(limit: 20);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch notifications'),
        (_) => fail('Expected Left'),
      );
    });

    test('returns Left with generic exception text', () async {
      when(
        () => mockDataSource.getNotifications(
          limit: any(named: 'limit'),
          cursor: any(named: 'cursor'),
        ),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.getNotifications(limit: 20);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message.contains('Exception'), true),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('markAllAsSeen', () {
    test('returns Right(unit) on success', () async {
      when(() => mockDataSource.markAllAsSeen()).thenAnswer((_) async {});

      final result = await repository.markAllAsSeen();

      expect(result, const Right(unit));
      verify(() => mockDataSource.markAllAsSeen()).called(1);
    });

    test('returns Left when markAllAsSeen throws ServerException', () async {
      when(
        () => mockDataSource.markAllAsSeen(),
      ).thenThrow(ServerException('Failed to mark notifications as seen'));

      final result = await repository.markAllAsSeen();

      expect(result.isLeft(), true);
      result.fold(
        (failure) =>
            expect(failure.message, 'Failed to mark notifications as seen'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('watchNewNotifications', () {
    test(
      'filters out NEW_MESSAGE and emits only POST_* notifications',
      () async {
        when(
          () => mockRealtimeDataSource.watchNewNotifications(any()),
        ).thenAnswer(
          (_) => Stream<Map<String, dynamic>>.fromIterable([
            {'id': 'n1', 'type': 'NEW_MESSAGE'},
            {'id': 'n2', 'type': 'POST_LIKE'},
            {'id': 'n3', 'type': 'POST_COMMENT'},
            {'id': 'n4', 'type': 'UNKNOWN'},
          ]),
        );

        final emissions = await repository
            .watchNewNotifications('receiver-1')
            .take(2)
            .toList();

        expect(emissions.length, 2);
        verify(
          () => mockRealtimeDataSource.watchNewNotifications('receiver-1'),
        ).called(1);
      },
    );
  });
}
