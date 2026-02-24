import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/notification/data/data_sources/notification_data_source.dart';
import 'package:conet_app/feature/notification/data/models/notification_page_model.dart';

class NotificationDataSourceImpl implements NotificationDataSource {
  final DioClient _dioClient;

  NotificationDataSourceImpl({required DioClient dioClient})
    : _dioClient = dioClient;

  @override
  Future<NotificationPageModel> getNotifications({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: queryParams,
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to fetch notifications');
      }

      return NotificationPageModel.fromJson(
        response.data as Map<String, dynamic>,
        limit: limit,
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> markAllAsSeen() async {
    try {
      final response = await _dioClient.dio.post('/notifications/mark-seen');

      if (response.statusCode != 200) {
        throw ServerException('Failed to mark notifications as seen');
      }
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
