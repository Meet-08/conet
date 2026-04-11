part of 'payment_bloc.dart';

abstract class PaymentEvent {}

class PaymentInitiateEvent extends PaymentEvent {
  final String registrationId;
  PaymentInitiateEvent(this.registrationId);
}

class PaymentRevertRegistrationEvent extends PaymentEvent {
  final String registrationId;
  final String? reason;

  PaymentRevertRegistrationEvent(this.registrationId, {this.reason});
}

class PaymentCreateOrganizerAccountEvent extends PaymentEvent {
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

  PaymentCreateOrganizerAccountEvent({
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

class PaymentGetOrganizerAccountEvent extends PaymentEvent {}
