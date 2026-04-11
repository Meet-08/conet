import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetOrganizerAccount {
  final PaymentRepository _repository;

  GetOrganizerAccount(this._repository);

  Future<Either<AppFailure, Map<String, dynamic>?>> call() {
    return _repository.getOrganizerAccount();
  }
}
