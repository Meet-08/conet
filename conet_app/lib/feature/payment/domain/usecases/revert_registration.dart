import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:fpdart/fpdart.dart';

class RevertRegistration {
  final PaymentRepository _repository;

  RevertRegistration(this._repository);

  Future<Either<AppFailure, void>> call(
    String registrationId, {
    String? reason,
  }) {
    return _repository.revertRegistration(registrationId, reason: reason);
  }
}
