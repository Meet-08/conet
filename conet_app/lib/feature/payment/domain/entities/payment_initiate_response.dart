import 'package:equatable/equatable.dart';

class PaymentInitiateResponse extends Equatable {
  final String paymentId;
  final String razorpayOrderId;
  final num amount;
  final String currency;

  const PaymentInitiateResponse({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
  });

  factory PaymentInitiateResponse.fromJson(Map<String, dynamic> json) {
    return PaymentInitiateResponse(
      paymentId: json['payment_id'] as String? ?? '',
      razorpayOrderId:
          json['razorpay_order_id'] as String? ??
          json['razorpay_order_details']?['id'] as String? ??
          '',
      amount: json['amount'] as num? ?? 0,
      currency: json['currency'] as String? ?? 'INR',
    );
  }

  @override
  List<Object?> get props => [paymentId, razorpayOrderId, amount, currency];
}
