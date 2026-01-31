import 'package:flutter/material.dart';
import 'package:khata/widgets/quick_add_customer_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/customer.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/customer_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../customers/add_customer_screen.dart';
import '../../widgets/cash_payment_confirmation_dialog.dart';
import 'bill_details_screen.dart';
import 'upi_demo_payment_screen.dart';
import 'pay_later_confirmation_screen.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _showProductSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ProductSearchSheet(),
    );
  }

  void _showCustomerSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CustomerSearchSheet(),
    );
  }

  void _showPaymentOptions() {
    final billProvider = context.read<BillProvider>();

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
            const Text(
              'Select Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption(
              icon: Icons.money,
              title: 'Cash',
              subtitle: 'Pay with cash',
              value: AppConstants.paymentCash,
              selected: billProvider.paymentType == AppConstants.paymentCash,
              onTap: () {
                billProvider.setPaymentType(AppConstants.paymentCash);
                Navigator.pop(context);
              },
            ),
            _buildPaymentOption(
              icon: Icons.qr_code,
              title: 'UPI',
              subtitle: 'Pay via UPI (Demo Mode)', // UPDATED subtitle
              value: AppConstants.paymentUpi,
              selected: billProvider.paymentType == AppConstants.paymentUpi,
              onTap: () {
                billProvider.setPaymentType(AppConstants.paymentUpi);
                Navigator.pop(context);
              },
              // ADD this optional parameter to show demo badge
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
            _buildPaymentOption(
              icon: Icons.credit_card,
              title: 'Card',
              subtitle: 'Pay with card',
              value: AppConstants.paymentCard,
              selected: billProvider.paymentType == AppConstants.paymentCard,
              onTap: () {
                billProvider.setPaymentType(AppConstants.paymentCard);
                Navigator.pop(context);
              },
            ),
            if (billProvider.selectedCustomer != null)
              _buildPaymentOption(
                icon: Icons.schedule,  // Changed from wallet icon
                title: 'Pay Later (Udhaar)',
                subtitle: 'Add to ${billProvider.selectedCustomer!.name}\'s dues',
                value: AppConstants.paymentCredit,
                selected: billProvider.paymentType == AppConstants.paymentCredit,
                isCredit: true,
                onTap: () {
                  billProvider.setPaymentType(AppConstants.paymentCredit);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // UPDATE _buildPaymentOption to accept trailing widget
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool selected,
    bool isCredit = false,
    required VoidCallback onTap,
    Widget? trailing, // ADD this parameter
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        tileColor: selected ? AppTheme.primaryColor.withOpacity(0.05) : null,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: (isCredit ? AppTheme.warningColor : AppTheme.primaryColor)
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isCredit ? AppTheme.warningColor : AppTheme.primaryColor,
          ),
        ),
        title: Row(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppTheme.successColor)
            : const Icon(Icons.circle_outlined, color: AppTheme.borderColor),
      ),
    );
  }

  Future<void> _createBill() async {
    final billProvider = context.read<BillProvider>();

    // Validate cart
    if (billProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the bill'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // ==================== HANDLE UDHAAR / PAY LATER ====================
    // Udhaar explicitly means unpaid - no confirmation needed
    if (billProvider.paymentType == AppConstants.paymentCredit) {
      await _handlePayLaterBill();
      return;
    }

    // ==================== HANDLE UPI PAYMENT ====================
    if (billProvider.paymentType == AppConstants.paymentUpi) {
      await _handleUpiPayment();
      return;
    }

    // ==================== HANDLE CASH PAYMENT ====================
    if (billProvider.paymentType == AppConstants.paymentCash) {
      await _handleCashPayment();
      return;
    }

    // ==================== HANDLE CARD AND OTHER PAYMENT TYPES ====================
    await _handleDirectPayment();
  }

  /// Handle Pay Later / Udhaar / Credit bill creation
  /// - No confirmation dialog needed
  /// - Bill is automatically marked as UNPAID
  /// - Shows Pay Later confirmation screen
  Future<void> _handlePayLaterBill() async {
    final billProvider = context.read<BillProvider>();

    // Validate customer is selected for credit
    if (billProvider.selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a customer for Pay Later'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Show confirmation that it will be added to customer's dues
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.schedule,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Add to Pay Later?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will add ₹${billProvider.total.toStringAsFixed(0)} to ${billProvider.selectedCustomer!.name}\'s pending dues.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.warningColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bill will be marked as unpaid',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: const Text('Add to Pay Later'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Create the bill (it's already marked as UNPAID in createBill for credit type)
    final bill = await billProvider.createBill();

    if (bill != null && mounted) {
      // Navigate to Pay Later confirmation screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PayLaterConfirmationScreen(bill: bill),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billProvider.error ?? 'Failed to create bill'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _handleUpiPayment() async {
    final billProvider = context.read<BillProvider>();

    // Create bill first (as unpaid)
    final bill = await billProvider.createBillForUpiPayment();

    if (bill != null && mounted) {
      // Show UPI payment screen
      final upiResult = await UpiDemoPaymentScreen.show(
        context,
        bill: bill,
      );

      if (upiResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill ${bill.billNumber} paid successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(
              billId: bill.id,
              isNewBill: true,
            ),
          ),
        );
      } else {
        // Payment cancelled or failed - bill remains unpaid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              upiResult.cancelled
                  ? 'Payment cancelled. Bill saved as unpaid.'
                  : 'Payment not received. Bill saved as unpaid.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(
              billId: bill.id,
              isNewBill: true,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleCashPayment() async {
    final billProvider = context.read<BillProvider>();

    // Create the bill first
    final bill = await billProvider.createBill();

    if (bill != null && mounted) {
      // Show cash confirmation dialog
      final cashStatus = await CashPaymentConfirmationDialog.show(
        context,
        amount: bill.total,
        billNumber: bill.billNumber,
      );

      // Update status based on user selection
      if (cashStatus == CashPaymentStatus.notPaid) {
        await billProvider.updateBillPaymentStatus(
          billId: bill.id,
          isPaid: false,
        );
      }
      // If paid or cancelled, status remains as set during creation

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cashStatus == CashPaymentStatus.paid
                  ? 'Bill ${bill.billNumber} created successfully!'
                  : 'Bill ${bill.billNumber} saved as unpaid.',
            ),
            backgroundColor: cashStatus == CashPaymentStatus.paid
                ? AppTheme.successColor
                : AppTheme.warningColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BillDetailScreen(
              billId: bill.id,
              isNewBill: true,
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleDirectPayment() async {
    final billProvider = context.read<BillProvider>();

    final bill = await billProvider.createBill();

    if (bill != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bill ${bill.billNumber} created successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(
            billId: bill.id,
            isNewBill: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(billProvider.error ?? 'Failed to create bill'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Create Bill'),
        actions: [
          Consumer<BillProvider>(
            builder: (context, provider, _) {
              if (provider.cartItems.isEmpty) return const SizedBox();
              return TextButton(
                onPressed: () {
                  provider.clearCart();
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<BillProvider>(
        builder: (context, billProvider, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Selection
                      const Text(
                        'Customer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _showCustomerSearch,
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  billProvider.selectedCustomer != null
                                      ? Icons.person
                                      : Icons.person_add_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  billProvider.selectedCustomer?.name ?? 'Select Customer (Optional)',
                                  style: TextStyle(
                                    color: billProvider.selectedCustomer != null
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                                    fontWeight: billProvider.selectedCustomer != null
                                        ? FontWeight.w500
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (billProvider.selectedCustomer != null)
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => billProvider.setCustomer(null),
                                )
                              else
                                const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Add Products Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Items',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showProductSearch,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Cart Items
                      if (billProvider.cartItems.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No items added',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _showProductSearch,
                                  child: const Text('Add products'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: billProvider.cartItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = billProvider.cartItems[index];
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            currencyFormat.format(item.price),
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Quantity Controls
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: () {
                                              if (item.quantity > 1) {
                                                billProvider.updateCartItemQuantity(
                                                  item.productId,
                                                  item.quantity - 1,
                                                );
                                              } else {
                                                billProvider.removeFromCart(item.productId);
                                              }
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                          Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              billProvider.updateCartItemQuantity(
                                                item.productId,
                                                item.quantity + 1,
                                              );
                                            },
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Item Total
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        currencyFormat.format(item.total),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Discount
                      if (billProvider.cartItems.isNotEmpty) ...[
                        const Text(
                          'Discount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomTextField(
                          hint: 'Enter discount amount',
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(Icons.discount_outlined),
                          onChanged: (value) {
                            final discount = double.tryParse(value) ?? 0;
                            billProvider.setDiscount(discount);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Payment Method
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Payment Method',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: _showPaymentOptions,
                              child: Text(
                                billProvider.paymentType,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: _showPaymentOptions,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getPaymentIcon(billProvider.paymentType),
                                  color: billProvider.paymentType == AppConstants.paymentCredit
                                      ? AppTheme.warningColor
                                      : AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _getPaymentLabel(billProvider.paymentType),
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Summary
              if (billProvider.cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Summary
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal'),
                            Text(currencyFormat.format(billProvider.subtotal)),
                          ],
                        ),
                        if (billProvider.discount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount'),
                              Text(
                                '- ${currencyFormat.format(billProvider.discount)}',
                                style: const TextStyle(color: AppTheme.successColor),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              currencyFormat.format(billProvider.total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Create Bill Button
                        CustomButton(
                          text: 'Create Bill (${billProvider.totalItems} items)',
                          isLoading: billProvider.isLoading,
                          onPressed: _createBill,
                          icon: Icons.receipt_long,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
      case AppConstants.paymentCredit:
        return Icons.account_balance_wallet;
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
      case AppConstants.paymentCredit:
        return 'Credit (Udhaar)';
      default:
        return type;
    }
  }
}

// Product Search Sheet
class ProductSearchSheet extends StatefulWidget {
  const ProductSearchSheet({super.key});

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  final _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _filteredProducts = context.read<ProductProvider>().products;
  }

  void _searchProducts(String query) {
    final products = context.read<ProductProvider>().products;
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = products;
      } else {
        _filteredProducts = products
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _searchProducts('');
                  },
                )
                    : null,
              ),
              onChanged: _searchProducts,
            ),
          ),
          // Product List
          Expanded(
            child: _filteredProducts.isEmpty
                ? const Center(
              child: Text('No products found'),
            )
                : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  title: Text(product.name),
                  subtitle: Text(
                    '${currencyFormat.format(product.sellingPrice)} • Stock: ${product.stock}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppTheme.primaryColor,
                    ),
                    onPressed: () {
                      context.read<BillProvider>().addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    context.read<BillProvider>().addToCart(product);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Customer Search Sheet
class CustomerSearchSheet extends StatefulWidget {
  const CustomerSearchSheet({super.key});

  @override
  State<CustomerSearchSheet> createState() => _CustomerSearchSheetState();
}

class _CustomerSearchSheetState extends State<CustomerSearchSheet> {
  final _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = context.read<CustomerProvider>().customers;
  }

  void _searchCustomers(String query) {
    final customers = context.read<CustomerProvider>().customers;
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = customers;
      } else {
        _filteredCustomers = customers
            .where((c) =>
        c.name.toLowerCase().contains(query.toLowerCase()) ||
            c.phone.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search customers...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: _searchCustomers,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    tooltip: 'Add New Customer',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (value) async {
                      if (value == 'quick') {
                        // Quick add - minimal dialog
                        final result = await QuickAddCustomerDialog.show(context);
                        if (result.hasCustomer && mounted) {
                          context.read<BillProvider>().setCustomer(result.customer as Customer?);
                          Navigator.pop(context);
                        }
                      } else if (value == 'full') {
                        // Full add - navigate to full screen
                        final customer = await Navigator.push<Customer>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddCustomerScreen(),
                          ),
                        );
                        if (customer != null && mounted) {
                          context.read<BillProvider>().setCustomer(customer);
                          Navigator.pop(context);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'quick',
                        child: Row(
                          children: [
                            Icon(Icons.flash_on, color: AppTheme.warningColor),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick Add'),
                                Text(
                                  'Name & Phone only',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'full',
                        child: Row(
                          children: [
                            Icon(Icons.person_add, color: AppTheme.primaryColor),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Full Details'),
                                Text(
                                  'All customer info',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Customer List
          Expanded(
            child: _filteredCustomers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No customers found'),
                  TextButton.icon(
                    onPressed: () async {
                      final customer = await Navigator.push<Customer>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddCustomerScreen(),
                        ),
                      );
                      if (customer != null && mounted) {
                        context.read<BillProvider>().setCustomer(customer);
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Customer'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredCustomers.length,
              itemBuilder: (context, index) {
                final customer = _filteredCustomers[index];
                return ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
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
                  title: Text(customer.name),
                  subtitle: Text(customer.phone),
                  onTap: () {
                    context.read<BillProvider>().setCustomer(customer);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}