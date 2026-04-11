import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/error_handler.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/payment/data/models/payment_initiate_model.dart';
import 'package:logger/logger.dart';

abstract interface class PaymentDataSource {
  Future<PaymentInitiateModel> initiatePayment(String registrationId);
  Future<void> revertRegistration(String registrationId, {String? reason});
  Future<void> createOrganizerAccount(Map<String, dynamic> payload);
  Future<Map<String, dynamic>?> getOrganizerAccount();
}

class PaymentDataSourceImpl implements PaymentDataSource {
  final DioClient _dioClient;
  final Logger _logger;

  PaymentDataSourceImpl(this._dioClient) : _logger = Logger();

  @override
  Future<PaymentInitiateModel> initiatePayment(String registrationId) async {
    try {
      final response = await _dioClient.dio.post(
        '/payments/$registrationId/initiate',
      );
      final body = response.data as Map<String, dynamic>;
      final payment = (body['payment'] as Map<String, dynamic>?) ?? body;
      return PaymentInitiateModel.fromJson(payment);
    } catch (e) {
      _logger.e('initiatePayment failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> revertRegistration(
    String registrationId, {
    String? reason,
  }) async {
    try {
      await _dioClient.dio.post(
        '/payments/$registrationId/revert',
        data: {
          if (reason != null && reason.trim().isNotEmpty)
            'reason': reason.trim(),
        },
      );
    } catch (e) {
      _logger.e('revertRegistration failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<void> createOrganizerAccount(Map<String, dynamic> payload) async {
    try {
      await _dioClient.dio.post('/payments/organizer-account', data: payload);
    } catch (e) {
      _logger.e('createOrganizerAccount failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }

  @override
  Future<Map<String, dynamic>?> getOrganizerAccount() async {
    try {
      final response = await _dioClient.dio.get('/payments/organizer-account');
      final body = response.data as Map<String, dynamic>?;
      if (body == null) return null;
      final account = body['account'];
      if (account is Map<String, dynamic>) return account;
      return body;
    } catch (e) {
      _logger.e('getOrganizerAccount failed', error: e);
      if (e is ServerException) rethrow;
      throw ServerException(AppErrorHandler.handleException(e), e);
    }
  }
}
