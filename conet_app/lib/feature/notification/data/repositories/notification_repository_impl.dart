import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_data_source.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_realtime_data_source.dart';
import 'package:conet_app/feature/notification/domain/entities/notification_page.dart';
import 'package:conet_app/feature/notification/domain/repositories/notification_repository.dart';
import 'package:fpdart/fpdart.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationDataSource _dataSource;
  final NotificationRealtimeDataSource _realtimeDataSource;

  NotificationRepositoryImpl({
    required NotificationDataSource dataSource,
    required NotificationRealtimeDataSource realtimeDataSource,
  }) : _dataSource = dataSource,
       _realtimeDataSource = realtimeDataSource;

  @override
  Future<Either<AppFailure, NotificationPage>> getNotifications({
    int limit = 20,
    String? cursor,
  }) {
    return _getResult<NotificationPage>(() async {
      final model = await _dataSource.getNotifications(
        limit: limit,
        cursor: cursor,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<AppFailure, Unit>> markAllAsSeen() {
    return _getResult<Unit>(() async {
      await _dataSource.markAllAsSeen();
      return unit;
    });
  }

  @override
  Stream<void> watchNewNotifications(String userId) {
    return _realtimeDataSource
        .watchNewNotifications(userId)
        .where((record) {
          final type = record['type'] as String?;
          // Only POST_LIKE and POST_COMMENT — skip NEW_MESSAGE
          return type == 'POST_LIKE' || type == 'POST_COMMENT';
        })
        .map((_) {});
  }

  Future<Either<AppFailure, T>> _getResult<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
