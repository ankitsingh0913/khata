// lib/widgets/cash_payment_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';

/// Result from cash payment confirmation
enum CashPaymentStatus {
  paid,
  notPaid,
  cancelled,
}

/// Dialog to confirm if cash payment was received
class CashPaymentConfirmationDialog extends StatelessWidget {
  final double amount;
  final String billNumber;

  const CashPaymentConfirmationDialog({
    super.key,
    required this.amount,
    required this.billNumber,
  });

  /// Show the dialog and return the result
  static Future<CashPaymentStatus> show(
      BuildContext context, {
        required double amount,
        required String billNumber,
      }) async {
    final result = await showDialog<CashPaymentStatus>(
      context: context,
      barrierDismissible: false, // Must make a choice
      builder: (context) => CashPaymentConfirmationDialog(
        amount: amount,
        billNumber: billNumber,
      ),
    );

    return result ?? CashPaymentStatus.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = '${AppConstants.currency}${amount.toStringAsFixed(0)}';

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cash Icon
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.payments_outlined,
              size: 36,
              color: AppTheme.successColor,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Cash Payment',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Amount
          Text(
            currencyFormat,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          // Bill number
          Text(
            'Bill: $billNumber',
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.help_outline,
                  color: AppTheme.warningColor,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Is the bill paid?',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              // Not Paid Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, CashPaymentStatus.notPaid);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 20),
                      SizedBox(width: 6),
                      Text('Not Paid'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Paid Button
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, CashPaymentStatus.paid);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      SizedBox(width: 6),
                      Text('Paid'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}