import 'package:conet_app/core/error/app_failure.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class DeviceRepository {
  Future<Either<AppFailure, void>> registerDevice({
    required String fcmToken,
    required String platform,
    String? deviceName,
  });

  Future<Either<AppFailure, void>> removeDevice({required String fcmToken});
}
