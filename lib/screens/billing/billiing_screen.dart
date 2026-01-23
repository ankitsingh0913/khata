import 'package:flutter/material.dart';
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
import 'bill_details_screen.dart';

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
              subtitle: 'Pay via UPI',
              value: AppConstants.paymentUpi,
              selected: billProvider.paymentType == AppConstants.paymentUpi,
              onTap: () {
                billProvider.setPaymentType(AppConstants.paymentUpi);
                Navigator.pop(context);
              },
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
                icon: Icons.account_balance_wallet,
                title: 'Credit (Udhaar)',
                subtitle: 'Add to customer dues',
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

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool selected,
    bool isCredit = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppTheme.successColor)
          : null,
      onTap: onTap,
    );
  }

  Future<void> _createBill() async {
    final billProvider = context.read<BillProvider>();

    if (billProvider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add items to cart'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final bill = await billProvider.createBill();

    if (bill != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill created successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => BillDetailScreen(billId: bill.id),
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
    _filteredProducts = context.read<ProductProvider>().products.cast<Product>();
  }

  void _searchProducts(String query) {
    final products = context.read<ProductProvider>().products;
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = products.cast<Product>();
      } else {
        _filteredProducts = products
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase())).cast<Product>()
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
                IconButton(
                  icon: const Icon(Icons.person_add),
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