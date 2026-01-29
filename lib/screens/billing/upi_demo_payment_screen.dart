import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../models/bill.dart';
import '../../providers/bill_provider.dart';
import '../../services/razorpay_demo_service.dart';
import 'bill_details_screen.dart';

/// Result of UPI demo payment flow
class UpiDemoPaymentFlowResult {
  final bool success;
  final bool cancelled;
  final String? transactionId;
  final Bill? updatedBill;

  UpiDemoPaymentFlowResult({
    this.success = false,
    this.cancelled = false,
    this.transactionId,
    this.updatedBill,
  });
}

/// UPI Demo Payment Screen
///
/// Shows a demo UPI QR code for testing purposes.
/// NO REAL MONEY is transferred.
class UpiDemoPaymentScreen extends StatefulWidget {
  final Bill bill;

  const UpiDemoPaymentScreen({
    super.key,
    required this.bill,
  });

  /// Show the UPI demo payment flow
  static Future<UpiDemoPaymentFlowResult> show(
      BuildContext context, {
        required Bill bill,
      }) async {
    final result = await Navigator.push<UpiDemoPaymentFlowResult>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiDemoPaymentScreen(bill: bill),
      ),
    );

    return result ?? UpiDemoPaymentFlowResult(cancelled: true);
  }

  @override
  State<UpiDemoPaymentScreen> createState() => _UpiDemoPaymentScreenState();
}

class _UpiDemoPaymentScreenState extends State<UpiDemoPaymentScreen> {
  final RazorpayDemoService _razorpayService = RazorpayDemoService();

  late DemoUpiQrData _qrData;
  Timer? _expiryTimer;
  Timer? _countdownTimer;

  Duration _remainingTime = Duration.zero;
  bool _isProcessing = false;
  bool _paymentComplete = false;
  String? _transactionId;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
    _startExpiryTimer();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _generateQrCode() {
    _qrData = _razorpayService.generateDemoQrCode(
      billId: widget.bill.id,
      billNumber: widget.bill.billNumber,
      amount: widget.bill.total,
    );
    _remainingTime = _qrData.remainingTime;
  }

  void _startExpiryTimer() {
    // Update countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingTime = _qrData.remainingTime;
          if (_remainingTime.isNegative) {
            timer.cancel();
            _handleQrExpired();
          }
        });
      }
    });
  }

  void _handleQrExpired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('QR Code Expired'),
        content: const Text('The payment QR code has expired. Would you like to generate a new one?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCancel();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _generateQrCode();
                _startExpiryTimer();
              });
            },
            child: const Text('Generate New QR'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMarkAsPaid() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate payment verification
      final result = await _razorpayService.simulatePaymentVerification(
        transactionRef: _qrData.transactionRef,
        amount: widget.bill.total,
        simulateSuccess: true,
      );

      if (result.success) {
        // Update bill status
        final billProvider = context.read<BillProvider>();
        await billProvider.updateBillPaymentStatus(
          billId: widget.bill.id,
          isPaid: true,
        );

        setState(() {
          _paymentComplete = true;
          _transactionId = result.transactionId;
        });

        // Show success and navigate
        if (mounted) {
          await _showSuccessDialog(result.transactionId!);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Payment failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleMarkAsUnpaid() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Unpaid?'),
        content: const Text(
          'The bill will be saved as unpaid. You can collect payment later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Mark Unpaid'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Update bill status
      final billProvider = context.read<BillProvider>();
      await billProvider.updateBillPaymentStatus(
        billId: widget.bill.id,
        isPaid: false,
      );

      Navigator.pop(
        context,
        UpiDemoPaymentFlowResult(
          success: false,
          cancelled: false,
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(String transactionId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 50,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.bill.total.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Bill', widget.bill.billNumber),
                  const SizedBox(height: 4),
                  _buildInfoRow('Transaction ID', transactionId),
                  const SizedBox(height: 4),
                  _buildInfoRow('Method', 'UPI (Demo)'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Demo label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppTheme.warningColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Demo Payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.warningColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(
                  context,
                  UpiDemoPaymentFlowResult(
                    success: true,
                    transactionId: transactionId,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View Receipt'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Payment?'),
        content: const Text(
          'Are you sure you want to cancel? The bill will remain unpaid.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(
                context,
                UpiDemoPaymentFlowResult(cancelled: true),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _copyUpiId() {
    Clipboard.setData(ClipboardData(text: _qrData.merchantVpa));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: AppConstants.currency,
      decimalDigits: 0,
    );

    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;

    return WillPopScope(
      onWillPop: () async {
        _handleCancel();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Pay with UPI'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleCancel,
          ),
          actions: [
            // Demo mode badge
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.warningColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'DEMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Demo Warning Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _razorpayService.demoDisclaimer,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Amount Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      const Text(
                        'Amount to Pay',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currencyFormat.format(widget.bill.total),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bill: ${widget.bill.billNumber}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // QR Code Card
                Container(
                  padding: const EdgeInsets.all(24),
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
                  child: Column(
                    children: [
                      const Text(
                        'Scan QR Code to Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use any UPI app to scan',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            QrImageView(
                              data: _qrData.qrContent,
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (context, error) {
                                return const Center(
                                  child: Text('Error generating QR'),
                                );
                              },
                            ),
                            // Demo watermark
                            Positioned(
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'DEMO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.warningColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Expiry Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _remainingTime.inMinutes < 2
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: _remainingTime.inMinutes < 2
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Expires in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _remainingTime.inMinutes < 2
                                    ? AppTheme.errorColor
                                    : AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // UPI ID
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'UPI ID: ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Text(
                              _qrData.merchantVpa,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _copyUpiId,
                              child: const Icon(
                                Icons.copy,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transaction Details',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Merchant', _qrData.merchantName),
                      _buildDetailRow('Reference', _qrData.transactionRef),
                      _buildDetailRow(
                        'Customer',
                        widget.bill.customerName ?? 'Walk-in Customer',
                      ),
                      _buildDetailRow('Mode', 'UPI (Demo)'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                const Text(
                  'After scanning, confirm payment status:',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),

                // Mark as Paid Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleMarkAsPaid,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text(
                          'Mark as Paid (Demo)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Mark as Unpaid Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _handleMarkAsUnpaid,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cancel_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Payment Not Received',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}