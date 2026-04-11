import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/payment/data/data_sources/payment_data_source.dart';
import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';
import 'package:conet_app/feature/payment/domain/repositories/payment_repository.dart';
import 'package:fpdart/fpdart.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentDataSource _dataSource;

  PaymentRepositoryImpl(this._dataSource);

  @override
  Future<Either<AppFailure, PaymentInitiateResponse>> initiatePayment(
    String registrationId,
  ) async {
    try {
      final res = await _dataSource.initiatePayment(registrationId);
      return Right(res);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> revertRegistration(
    String registrationId, {
    String? reason,
  }) async {
    try {
      await _dataSource.revertRegistration(registrationId, reason: reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      await _dataSource.createOrganizerAccount({
        'account_holder_name': accountHolderName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'bank_name': bankName,
        'pan': pan,
        'title': title,
        'phone': phone,
        'email': email,
        'street1': street1,
        'street2': street2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
      });
      return const Right(null);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Map<String, dynamic>?>>
  getOrganizerAccount() async {
    try {
      final res = await _dataSource.getOrganizerAccount();
      return Right(res);
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
