import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';

abstract interface class DeviceRemoteDataSource {
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  });

  Future<void> removeDevice({required String fcmToken});
}

class DeviceRemoteDataSourceImpl implements DeviceRemoteDataSource {
  final DioClient _dioClient;

  DeviceRemoteDataSourceImpl(this._dioClient);

  @override
  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    try {
      await _dioClient.dio.post(
        '/devices/register',
        data: {
          'fcm_token': fcmToken,
          'platform': platform,
          'device_name': deviceName,
        },
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> removeDevice({required String fcmToken}) async {
    try {
      await _dioClient.dio.delete(
        '/devices/current',
        data: {'fcm_token': fcmToken},
      );
    } catch (e) {
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
