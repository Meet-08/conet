import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/device/domain/repository/device_repository.dart';
import 'package:fpdart/fpdart.dart';

class RemoveDeviceUseCase {
  final DeviceRepository _repository;

  RemoveDeviceUseCase(this._repository);

  Future<Either<AppFailure, void>> call(RemoveDeviceParams params) async {
    return await _repository.removeDevice(fcmToken: params.fcmToken);
  }
}

class RemoveDeviceParams {
  final String fcmToken;

  RemoveDeviceParams({required this.fcmToken});
}
