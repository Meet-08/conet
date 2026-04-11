import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateOrganizerAccountParams {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String pan;
  final String title;
  final String phone;
  final String email;
  final String street1;
  final String street2;
  final String city;
  final String state;
  final String postalCode;
  final String country;

  CreateOrganizerAccountParams({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    required this.pan,
    required this.title,
    required this.phone,
    required this.email,
    required this.street1,
    required this.street2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
  });
}

class CreateOrganizerAccount {
  final PaymentRepository _repository;

  CreateOrganizerAccount(this._repository);

  Future<Either<AppFailure, void>> call(CreateOrganizerAccountParams params) {
    return _repository.createOrganizerAccount(
      accountHolderName: params.accountHolderName,
      accountNumber: params.accountNumber,
      ifscCode: params.ifscCode,
      bankName: params.bankName,
      pan: params.pan,
      title: params.title,
      phone: params.phone,
      email: params.email,
      street1: params.street1,
      street2: params.street2,
      city: params.city,
      state: params.state,
      postalCode: params.postalCode,
      country: params.country,
    );
  }
}
