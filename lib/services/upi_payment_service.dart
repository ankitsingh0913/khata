import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Data class for UPI QR code generation
class UpiQrData {
  final String qrContent;
  final String billId;
  final String billNumber;
  final double amount;
  final String merchantName;
  final String merchantVpa;
  final String transactionRef;
  final DateTime generatedAt;
  final DateTime expiresAt;

  UpiQrData({
    required this.qrContent,
    required this.billId,
    required this.billNumber,
    required this.amount,
    required this.merchantName,
    required this.merchantVpa,
    required this.transactionRef,
    DateTime? generatedAt,
    DateTime? expiresAt,
  })  : generatedAt = generatedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 10));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}

/// UPI Payment Service
///
/// Generates real UPI QR code strings using the shopkeeper's
/// actual UPI ID. When a customer scans this QR with any UPI app
/// (GPay, PhonePe, Paytm), it will initiate a real payment.
class UpiPaymentService {
  static final UpiPaymentService _instance = UpiPaymentService._internal();
  factory UpiPaymentService() => _instance;
  UpiPaymentService._internal();

  /// Generate a unique transaction reference for tracking
  String _generateTransactionRef(String billId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$billId-$timestamp';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return 'TXN${hash.toString().substring(0, 12).toUpperCase()}';
  }

  /// Generate a real UPI QR code for payment
  ///
  /// The generated QR string follows the standard UPI deep-link format:
  ///   upi://pay?pa=VPA&pn=NAME&am=AMOUNT&tr=REF&tn=NOTE&cu=INR
  ///
  /// Any UPI app can read this format and initiate a real payment.
  UpiQrData generateUpiQrCode({
    required String merchantVpa,
    required String merchantName,
    required String billId,
    required String billNumber,
    required double amount,
  }) {
    final transactionRef = _generateTransactionRef(billId);

    // Standard UPI QR code format
    final qrContent = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': merchantVpa,                           // Payee VPA (shopkeeper's UPI ID)
        'pn': merchantName,                          // Payee Name
        'am': amount.toStringAsFixed(2),             // Amount
        'tr': transactionRef,                        // Transaction Reference
        'tn': 'Payment for Bill $billNumber',        // Transaction Note
        'cu': 'INR',                                 // Currency
        'mode': '02',                                // QR mode
      },
    ).toString();

    if (kDebugMode) {
      print('Generated UPI QR: $qrContent');
    }

    return UpiQrData(
      qrContent: qrContent,
      billId: billId,
      billNumber: billNumber,
      amount: amount,
      merchantName: merchantName,
      merchantVpa: merchantVpa,
      transactionRef: transactionRef,
    );
  }
}
