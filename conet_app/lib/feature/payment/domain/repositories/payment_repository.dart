import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PaymentRepository {
  Future<Either<AppFailure, PaymentInitiateResponse>> initiatePayment(
    String registrationId,
  );
  Future<Either<AppFailure, void>> revertRegistration(
    String registrationId, {
    String? reason,
  });
  Future<Either<AppFailure, void>> createOrganizerAccount({
    required String accountHolderName,
    required String accountNumber,
    required String ifscCode,
    required String bankName,
    required String pan,
    required String title,
    required String phone,
    required String email,
    required String street1,
    required String street2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
  });
  Future<Either<AppFailure, Map<String, dynamic>?>> getOrganizerAccount();
}
