// lib/config/app_constants.dart
class AppConstants {
  static const String appName = 'Smart Shopkeeper';
  static const String currency = '₹';

  // Payment Types
  static const String paymentCash = 'CASH';
  static const String paymentUpi = 'UPI';
  static const String paymentCredit = 'CREDIT';
  static const String paymentCard = 'CARD';

  // Bill Status
  static const String billPaid = 'PAID';
  static const String billPartial = 'PARTIAL';
  static const String billUnpaid = 'UNPAID';

  // Database
  static const String dbName = 'smart_shopkeeper.db';
  static const int dbVersion = 1;
}