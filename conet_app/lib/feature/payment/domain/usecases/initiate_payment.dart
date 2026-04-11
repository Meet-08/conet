import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:fpdart/fpdart.dart';

class InitiatePayment {
  final PaymentRepository _repository;

  InitiatePayment(this._repository);

  Future<Either<AppFailure, PaymentInitiateResponse>> call(
    String registrationId,
  ) {
    return _repository.initiatePayment(registrationId);
  }
}
