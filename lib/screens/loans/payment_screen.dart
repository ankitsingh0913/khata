import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/customer.dart';
import '../../models/bill.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/cash_payment_confirmation_dialog.dart';
import '../billing/upi_demo_payment_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Customer? customer;
  final Bill? bill;

  const PaymentScreen({super.key, this.customer, this.bill});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedPaymentType = AppConstants.paymentCash;
  bool _isLoading = false;
  List<Bill> _unpaidBills = [];
  Bill? _selectedBill;

  @override
  void initState() {
    super.initState();
    _loadUnpaidBills();
    if (widget.bill != null) {
      _selectedBill = widget.bill;
      _amountController.text = widget.bill!.pendingAmount.toStringAsFixed(0);
    }
  }

  Future<void> _loadUnpaidBills() async {
    if (widget.customer != null) {
      await context.read<BillProvider>().loadBillsByCustomer(widget.customer!.id);
      if (mounted) {
        setState(() {
          _unpaidBills = context.read<BillProvider>().bills
              .where((b) => !b.isPaid)
              .toList();

          // If no bill is selected and we have unpaid bills, select the first one
          if (_selectedBill == null && _unpaidBills.isNotEmpty) {
            _selectedBill = _unpaidBills.first;
            _amountController.text = _selectedBill!.pendingAmount.toStringAsFixed(0);
          }
        });
      }
    } else if (widget.bill != null) {
      setState(() {
        _unpaidBills = [widget.bill!];
        _selectedBill = widget.bill;
        _amountController.text = widget.bill!.pendingAmount.toStringAsFixed(0);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Main payment recording method with Cash and UPI handling
  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bill'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final amount = double.parse(_amountController.text);

    // ==================== HANDLE UPI PAYMENT ====================
    if (_selectedPaymentType == AppConstants.paymentUpi) {
      await _handleUpiPayment(amount);
      return;
    }

    // ==================== HANDLE CASH PAYMENT ====================
    if (_selectedPaymentType == AppConstants.paymentCash) {
      await _handleCashPayment(amount);
      return;
    }

    // ==================== HANDLE OTHER PAYMENT TYPES (Card, etc.) ====================
    await _processPayment(amount, markAsPaid: true);
  }

  /// Handle UPI payment flow with QR code
  Future<void> _handleUpiPayment(double amount) async {
    // Create a temporary bill object for UPI screen
    // We use the selected bill's info but with the payment amount
    final billForUpi = _selectedBill!.copyWith(
      total: amount,
      paidAmount: 0,
      status: AppConstants.billUnpaid,
    );

    // Show UPI Demo Payment Screen
    final upiResult = await Navigator.push<UpiDemoPaymentFlowResult>(
      context,
      MaterialPageRoute(
        builder: (_) => UpiDemoPaymentScreen(bill: billForUpi),
      ),
    );

    if (upiResult == null || upiResult.cancelled) {
      // User cancelled - do nothing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI payment cancelled'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    if (upiResult.success) {
      // UPI payment successful - record the payment
      await _processPayment(amount, markAsPaid: true, isFromUpi: true);
    } else {
      // UPI payment not received
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not received'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  /// Handle Cash payment flow with confirmation dialog
  Future<void> _handleCashPayment(double amount) async {
    // Show cash payment confirmation dialog
    final cashStatus = await CashPaymentConfirmationDialog.show(
      context,
      amount: amount,
      billNumber: _selectedBill!.billNumber,
    );

    if (cashStatus == CashPaymentStatus.cancelled) {
      // User cancelled - do nothing
      return;
    }

    if (cashStatus == CashPaymentStatus.paid) {
      // Cash received - record payment
      await _processPayment(amount, markAsPaid: true);
    } else {
      // Cash not received - don't record payment, just show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment not received. Bill remains unpaid.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    }
  }

  /// Process the actual payment recording
  Future<void> _processPayment(
      double amount, {
        required bool markAsPaid,
        bool isFromUpi = false,
      }) async {
    if (!markAsPaid) return;

    setState(() => _isLoading = true);

    try {
      final success = await context.read<BillProvider>().recordPayment(
        billId: _selectedBill!.id,
        amount: amount,
        paymentType: _selectedPaymentType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (!mounted) return;

      if (success) {
        // Refresh customer data
        if (widget.customer != null) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            await context.read<CustomerProvider>().loadCustomers();
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isFromUpi
                    ? 'UPI payment of ₹${amount.toStringAsFixed(0)} recorded!'
                    : 'Payment of ₹${amount.toStringAsFixed(0)} recorded successfully!',
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to record payment'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show payment method selection bottom sheet
  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Cash Option
            _buildPaymentMethodTile(
              icon: Icons.money,
              title: 'Cash',
              subtitle: 'Receive cash payment',
              value: AppConstants.paymentCash,
              color: AppTheme.successColor,
            ),

            // UPI Option with Demo badge
            _buildPaymentMethodTile(
              icon: Icons.qr_code,
              title: 'UPI',
              subtitle: 'Pay via UPI QR code',
              value: AppConstants.paymentUpi,
              color: AppTheme.primaryColor,
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DEMO',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Card Option
            _buildPaymentMethodTile(
              icon: Icons.credit_card,
              title: 'Card',
              subtitle: 'Debit or Credit card',
              value: AppConstants.paymentCard,
              color: AppTheme.accentColor,
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required Color color,
    Widget? trailing,
  }) {
    final isSelected = _selectedPaymentType == value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () {
          setState(() => _selectedPaymentType = value);
          Navigator.pop(context);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        tileColor: isSelected ? color.withOpacity(0.05) : null,
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: AppTheme.successColor)
            : const Icon(Icons.circle_outlined, color: AppTheme.borderColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);
    final customer = widget.customer;
    final bill = widget.bill ?? _selectedBill;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Collect Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Info Card
              if (customer != null)
                Container(
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
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              customer.phone,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Total Pending',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currencyFormat.format(customer.pendingAmount),
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Select Bill (if multiple unpaid bills)
              if (widget.bill == null && _unpaidBills.isNotEmpty) ...[
                const Text(
                  'Select Bill',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Bill>(
                      value: _selectedBill,
                      isExpanded: true,
                      hint: const Text('Select a bill'),
                      items: _unpaidBills.map((bill) {
                        return DropdownMenuItem(
                          value: bill,
                          child: Text(
                            '${bill.billNumber} - ${currencyFormat.format(bill.pendingAmount)} pending',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBill = value;
                          if (value != null) {
                            _amountController.text = value.pendingAmount.toStringAsFixed(0);
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Selected Bill Info
              if (bill != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.receipt_outlined,
                                size: 18,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                bill.billNumber,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ${currencyFormat.format(bill.total)}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Pending',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            currencyFormat.format(bill.pendingAmount),
                            style: const TextStyle(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Payment Amount
              const Text(
                'Payment Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: 'Enter amount',
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.currency_rupee),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter valid amount';
                  }
                  if (bill != null && amount > bill.pendingAmount) {
                    return 'Amount cannot exceed pending amount';
                  }
                  return null;
                },
              ),

              // Quick Amount Buttons
              if (bill != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildQuickAmountChip(bill.pendingAmount, 'Full Amount'),
                    if (bill.pendingAmount > 100)
                      _buildQuickAmountChip(100, '₹100'),
                    if (bill.pendingAmount > 500)
                      _buildQuickAmountChip(500, '₹500'),
                    if (bill.pendingAmount > 1000)
                      _buildQuickAmountChip(1000, '₹1000'),
                    if (bill.pendingAmount > 2000)
                      _buildQuickAmountChip(2000, '₹2000'),
                  ],
                ),
              ],
              const SizedBox(height: 24),

              // Payment Method
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showPaymentMethodPicker,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: _getPaymentColor(_selectedPaymentType).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _getPaymentIcon(_selectedPaymentType),
                          color: _getPaymentColor(_selectedPaymentType),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _getPaymentLabel(_selectedPaymentType),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (_selectedPaymentType == AppConstants.paymentUpi) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'DEMO',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const Text(
                              'Tap to change',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CustomTextField(
                hint: 'Add any notes for this payment',
                controller: _notesController,
                maxLines: 2,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 32),

              // Payment Method Info
              if (_selectedPaymentType == AppConstants.paymentUpi)
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
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'UPI Demo Mode: A QR code will be shown. No real money will be transferred.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_selectedPaymentType == AppConstants.paymentCash)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.successColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You will be asked to confirm if payment was received.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Record Payment Button
              CustomButton(
                text: _getButtonText(),
                isLoading: _isLoading,
                onPressed: _recordPayment,
                icon: _getButtonIcon(),
                backgroundColor: _getPaymentColor(_selectedPaymentType),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount, String label) {
    final isSelected = _amountController.text == amount.toStringAsFixed(0);

    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected
          ? AppTheme.primaryColor.withOpacity(0.2)
          : null,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
      ),
      onPressed: () {
        setState(() {
          _amountController.text = amount.toStringAsFixed(0);
        });
      },
    );
  }

  IconData _getPaymentIcon(String type) {
    switch (type) {
      case AppConstants.paymentCash:
        return Icons.money;
      case AppConstants.paymentUpi:
        return Icons.qr_code;
      case AppConstants.paymentCard:
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentLabel(String type) {
    switch (type) {
      case AppConstants.paymentCash:
        return 'Cash';
      case AppConstants.paymentUpi:
        return 'UPI';
      case AppConstants.paymentCard:
        return 'Card';
      default:
        return type;
    }
  }

  Color _getPaymentColor(String type) {
    switch (type) {
      case AppConstants.paymentCash:
        return AppTheme.successColor;
      case AppConstants.paymentUpi:
        return AppTheme.primaryColor;
      case AppConstants.paymentCard:
        return AppTheme.accentColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getButtonText() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final formattedAmount = '₹${amount.toStringAsFixed(0)}';

    switch (_selectedPaymentType) {
      case AppConstants.paymentCash:
        return 'Collect $formattedAmount Cash';
      case AppConstants.paymentUpi:
        return 'Show UPI QR for $formattedAmount';
      case AppConstants.paymentCard:
        return 'Record $formattedAmount Card Payment';
      default:
        return 'Record Payment';
    }
  }

  IconData _getButtonIcon() {
    switch (_selectedPaymentType) {
      case AppConstants.paymentCash:
        return Icons.payments_outlined;
      case AppConstants.paymentUpi:
        return Icons.qr_code;
      case AppConstants.paymentCard:
        return Icons.credit_card;
      default:
        return Icons.check;
    }
  }
}