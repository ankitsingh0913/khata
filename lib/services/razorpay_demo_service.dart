import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Demo/Sandbox mode indicator
const bool kRazorpayDemoMode = true;

/// Razorpay Test Keys (Sandbox - No real transactions)
class RazorpayTestCredentials {
  // These are TEST keys - they do NOT process real payments
  // Replace with your own test keys from Razorpay Dashboard

  static const String keyId = 'rzp_test_S8bTDK2S54hwkP'; // Replace with your test key
  static const String keySecret = 'rWYEns7GsfTai6qCy9CJUFvu'; // Replace with your test secret

  // Demo merchant info
  static const String merchantName = 'Smart Shopkeeper Demo';
  static const String merchantVpa = 'smartshop@razorpay'; // Demo VPA
}

/// Result of a demo UPI payment
class DemoUpiPaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final String paymentMethod;
  final double amount;
  final DateTime timestamp;
  final bool isDemo;

  DemoUpiPaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    required this.paymentMethod,
    required this.amount,
    DateTime? timestamp,
    this.isDemo = true,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'paymentMethod': paymentMethod,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'isDemo': isDemo,
    };
  }
}

/// Demo UPI QR Code Data
class DemoUpiQrData {
  final String qrContent;
  final String billId;
  final String billNumber;
  final double amount;
  final String merchantName;
  final String merchantVpa;
  final String transactionRef;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final bool isDemo;

  DemoUpiQrData({
    required this.qrContent,
    required this.billId,
    required this.billNumber,
    required this.amount,
    required this.merchantName,
    required this.merchantVpa,
    required this.transactionRef,
    DateTime? generatedAt,
    DateTime? expiresAt,
    this.isDemo = true,
  })  : generatedAt = generatedAt ?? DateTime.now(),
        expiresAt = expiresAt ?? DateTime.now().add(const Duration(minutes: 10));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remainingTime => expiresAt.difference(DateTime.now());
}

/// Razorpay Demo Service
/// 
/// This service provides sandbox/demo UPI payment functionality.
/// NO REAL MONEY is transferred. This is for testing purposes only.
/// 
/// For production, replace with actual Razorpay integration.
class RazorpayDemoService {
  static final RazorpayDemoService _instance = RazorpayDemoService._internal();
  factory RazorpayDemoService() => _instance;
  RazorpayDemoService._internal();

  /// Check if demo mode is enabled
  bool get isDemoMode => kRazorpayDemoMode;

  /// Generate a unique transaction reference
  String _generateTransactionRef(String billId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$billId-$timestamp';
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return 'DEMO${hash.toString().substring(0, 12).toUpperCase()}';
  }

  /// Generate UPI QR code data for demo payment
  /// 
  /// This generates a UPI-compatible QR code string that can be scanned
  /// by any UPI app. In demo mode, no real transaction will occur.
  DemoUpiQrData generateDemoQrCode({
    required String billId,
    required String billNumber,
    required double amount,
  }) {
    final transactionRef = _generateTransactionRef(billId);

    // Standard UPI QR code format
    // Format: upi://pay?pa=VPA&pn=NAME&am=AMOUNT&tr=TXNREF&tn=NOTE
    final qrContent = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': RazorpayTestCredentials.merchantVpa, // Payee VPA
        'pn': RazorpayTestCredentials.merchantName, // Payee Name
        'am': amount.toStringAsFixed(2), // Amount
        'tr': transactionRef, // Transaction Reference
        'tn': 'Payment for Bill $billNumber (DEMO)', // Transaction Note
        'cu': 'INR', // Currency
        'mode': '02', // QR mode
      },
    ).toString();

    if (kDebugMode) {
      print('Generated Demo UPI QR: $qrContent');
    }

    return DemoUpiQrData(
      qrContent: qrContent,
      billId: billId,
      billNumber: billNumber,
      amount: amount,
      merchantName: RazorpayTestCredentials.merchantName,
      merchantVpa: RazorpayTestCredentials.merchantVpa,
      transactionRef: transactionRef,
    );
  }

  /// Simulate payment verification (Demo only)
  /// 
  /// In a real implementation, this would verify with Razorpay servers.
  /// In demo mode, it simulates success/failure based on parameters.
  Future<DemoUpiPaymentResult> simulatePaymentVerification({
    required String transactionRef,
    required double amount,
    bool simulateSuccess = true,
    Duration delay = const Duration(seconds: 2),
  }) async {
    // Simulate network delay
    await Future.delayed(delay);

    if (simulateSuccess) {
      return DemoUpiPaymentResult(
        success: true,
        transactionId: 'DEMO_TXN_${DateTime.now().millisecondsSinceEpoch}',
        paymentMethod: 'UPI',
        amount: amount,
        isDemo: true,
      );
    } else {
      return DemoUpiPaymentResult(
        success: false,
        errorMessage: 'Demo payment failed (simulated)',
        paymentMethod: 'UPI',
        amount: amount,
        isDemo: true,
      );
    }
  }

  /// Check payment status (Demo simulation)
  /// 
  /// This would normally poll Razorpay for payment status.
  /// In demo mode, it returns a simulated status.
  Future<String> checkPaymentStatus(String transactionRef) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // In demo mode, always return pending
    // Real implementation would check with Razorpay API
    return 'pending';
  }

  /// Get demo mode disclaimer text
  String get demoDisclaimer =>
      '⚠️ DEMO MODE - No real money will be transferred. '
          'This is a sandbox payment for testing purposes only.';
}