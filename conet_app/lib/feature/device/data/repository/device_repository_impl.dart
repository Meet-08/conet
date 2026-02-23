import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/device/data/data_source/device_remote_data_source.dart';
import 'package:conet_app/feature/device/domain/repository/device_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;

  DeviceRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<AppFailure, void>> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  }) async {
    try {
      await _remoteDataSource.registerDevice(
        fcmToken: fcmToken,
        platform: platform,
        deviceName: deviceName,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    } catch (e) {
      return left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> removeDevice({
    required String fcmToken,
  }) async {
    try {
      await _remoteDataSource.removeDevice(fcmToken: fcmToken);
      return right(null);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    } catch (e) {
      return left(AppFailure(e.toString()));
    }
  }
}
