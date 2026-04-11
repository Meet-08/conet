import 'package:conet_app/feature/payment/domain/entities/payment_initiate_response.dart';

class PaymentInitiateModel extends PaymentInitiateResponse {
  const PaymentInitiateModel({
    required super.paymentId,
    required super.razorpayOrderId,
    required super.amount,
    required super.currency,
  });

  factory PaymentInitiateModel.fromJson(Map<String, dynamic> json) {
    return PaymentInitiateModel(
      paymentId: json['payment_id'] as String? ?? '',
      razorpayOrderId:
          json['razorpay_order_id'] as String? ??
          json['razorpay_order_details']?['id'] as String? ??
          '',
      amount: json['amount'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }
}
