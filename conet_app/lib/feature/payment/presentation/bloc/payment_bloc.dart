import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:conet_app/feature/payment/domain/usecases/create_organizer_account.dart';
import 'package:conet_app/feature/payment/domain/usecases/get_organizer_account.dart';
import 'package:conet_app/feature/payment/domain/usecases/initiate_payment.dart';
import 'package:conet_app/feature/payment/domain/usecases/revert_registration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final InitiatePayment _initiatePayment;
  final RevertRegistration _revertRegistration;
  final CreateOrganizerAccount _createOrganizerAccount;
  final GetOrganizerAccount _getOrganizerAccount;

  PaymentBloc({
    required InitiatePayment initiatePayment,
    required RevertRegistration revertRegistration,
    required CreateOrganizerAccount createOrganizerAccount,
    required GetOrganizerAccount getOrganizerAccount,
  }) : _initiatePayment = initiatePayment,
       _revertRegistration = revertRegistration,
       _createOrganizerAccount = createOrganizerAccount,
       _getOrganizerAccount = getOrganizerAccount,
       super(PaymentInitial()) {
    on<PaymentInitiateEvent>(_onInitiatePayment);
    on<PaymentRevertRegistrationEvent>(_onRevertRegistration);
    on<PaymentCreateOrganizerAccountEvent>(_onCreateOrganizerAccount);
    on<PaymentGetOrganizerAccountEvent>(_onGetOrganizerAccount);
  }

  Future<void> _onInitiatePayment(
    PaymentInitiateEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final failureOrSuccess = await _initiatePayment(event.registrationId);

    failureOrSuccess.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (response) => emit(PaymentInitiateSuccess(response)),
    );
  }

  Future<void> _onRevertRegistration(
    PaymentRevertRegistrationEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final failureOrSuccess = await _revertRegistration(
      event.registrationId,
      reason: event.reason,
    );

    failureOrSuccess.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (_) => emit(PaymentRevertRegistrationSuccess(event.registrationId)),
    );
  }

  Future<void> _onCreateOrganizerAccount(
    PaymentCreateOrganizerAccountEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final params = CreateOrganizerAccountParams(
      accountHolderName: event.accountHolderName,
      accountNumber: event.accountNumber,
      ifscCode: event.ifscCode,
      bankName: event.bankName,
      pan: event.pan,
      title: event.title,
      phone: event.phone,
      email: event.email,
      street1: event.street1,
      street2: event.street2,
      city: event.city,
      state: event.state,
      postalCode: event.postalCode,
      country: event.country,
    );

    final failureOrSuccess = await _createOrganizerAccount(params);

    failureOrSuccess.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (_) => emit(PaymentCreateOrganizerSuccess()),
    );
  }

  Future<void> _onGetOrganizerAccount(
    PaymentGetOrganizerAccountEvent event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());

    final failureOrSuccess = await _getOrganizerAccount();

    failureOrSuccess.fold(
      (failure) => emit(PaymentFailure(failure.message)),
      (account) => emit(PaymentGetOrganizerSuccess(account)),
    );
  }
}
