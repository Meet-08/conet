import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/device/domain/repository/device_repository.dart';
import 'package:fpdart/fpdart.dart';

class RegisterDeviceUseCase {
  final DeviceRepository _repository;

  RegisterDeviceUseCase(this._repository);

  Future<Either<AppFailure, void>> call(RegisterDeviceParams params) async {
    return await _repository.registerDevice(
      fcmToken: params.fcmToken,
      platform: params.platform,
      deviceName: params.deviceName,
    );
  }
}

class RegisterDeviceParams {
  final String fcmToken;
  final String platform;
  final String? deviceName;

  RegisterDeviceParams({
    required this.fcmToken,
    required this.platform,
    this.deviceName,
  });
}
