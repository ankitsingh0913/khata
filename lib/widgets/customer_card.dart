import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../config/app_theme.dart';
import '../config/app_constants.dart';

class CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback? onTap;
  final VoidCallback? onCall;

  const CustomerCard({
    super.key,
    required this.customer,
    this.onTap,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.phone,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Pending Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (customer.pendingAmount > 0) ...[
                  Text(
                    currencyFormat.format(customer.pendingAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const Text(
                    'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.successColor,
                    size: 24,
                  ),
                  const Text(
                    'Clear',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ],
            ),
            if (onCall != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCall,
                icon: const Icon(Icons.phone, color: AppTheme.successColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}