part of 'payment_bloc.dart';

abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentInitiateSuccess extends PaymentState {
  final PaymentInitiateResponse response;
  PaymentInitiateSuccess(this.response);
}

class PaymentRevertRegistrationSuccess extends PaymentState {
  final String registrationId;
  PaymentRevertRegistrationSuccess(this.registrationId);
}

class PaymentCreateOrganizerSuccess extends PaymentState {}

class PaymentGetOrganizerSuccess extends PaymentState {
  final Map<String, dynamic>? account;
  PaymentGetOrganizerSuccess(this.account);
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
}
