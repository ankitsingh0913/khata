// lib/screens/loans/payment_screen.dart
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

class PaymentScreen extends StatefulWidget {
  final Customer? customer;
  final Bill? bill;

  const PaymentScreen({super.key, this.bill, this.customer});

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
      _amountController.text = widget.bill!.pendingAmount.toString();
    }
  }

  Future<void> _loadUnpaidBills() async {
    if (widget.customer != null) {
      await context.read<BillProvider>().loadBillsByCustomer(widget.customer!.id);
      setState(() {
        _unpaidBills = context.read<BillProvider>().bills
            .where((b) => !b.isPaid)
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

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

    setState(() => _isLoading = true);

    final amount = double.parse(_amountController.text);
    final success = await context.read<BillProvider>().recordPayment(
      billId: _selectedBill!.id,
      amount: amount,
      paymentType: _selectedPaymentType,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Refresh customer data
      if (widget.customer != null) {
        await context.read<CustomerProvider>().loadCustomers();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment recorded successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
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
              // Customer Info
              if (customer != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            _amountController.text = value.pendingAmount.toString();
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
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bill.billNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Amount
              CustomTextField(
                label: 'Payment Amount *',
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
                  children: [
                    _buildQuickAmountChip(bill.pendingAmount, 'Full'),
                    if (bill.pendingAmount > 100) _buildQuickAmountChip(100, '₹100'),
                    if (bill.pendingAmount > 500) _buildQuickAmountChip(500, '₹500'),
                    if (bill.pendingAmount > 1000) _buildQuickAmountChip(1000, '₹1000'),
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
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildPaymentMethodChip(
                    AppConstants.paymentCash,
                    'Cash',
                    Icons.money,
                  ),
                  _buildPaymentMethodChip(
                    AppConstants.paymentUpi,
                    'UPI',
                    Icons.qr_code,
                  ),
                  _buildPaymentMethodChip(
                    AppConstants.paymentCard,
                    'Card',
                    Icons.credit_card,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes
              CustomTextField(
                label: 'Notes (Optional)',
                hint: 'Add any notes',
                controller: _notesController,
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Record Payment',
                isLoading: _isLoading,
                onPressed: _recordPayment,
                icon: Icons.check_circle_outline,
                backgroundColor: AppTheme.successColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(double amount, String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _amountController.text = amount.toString();
      },
    );
  }

  Widget _buildPaymentMethodChip(String value, String label, IconData icon) {
    final isSelected = _selectedPaymentType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}