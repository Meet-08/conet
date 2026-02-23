import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:dio/dio.dart';

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
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> removeDevice({required String fcmToken}) async {
    try {
      await _dioClient.dio.delete(
        '/devices/current',
        data: {'fcm_token': fcmToken},
      );
    } on DioException catch (e) {
      throw ServerException(e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
