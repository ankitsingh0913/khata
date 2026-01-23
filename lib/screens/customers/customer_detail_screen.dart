import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/bill_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/bill_card.dart';
import '../../widgets/custom_button.dart';
import '../../services/share_service.dart';
import '../billing/bill_details_screen.dart';
import '../loans/payment_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCustomerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerData() async {
    await context.read<CustomerProvider>().selectCustomer(widget.customer.id);
    await context.read<BillProvider>().loadBillsByCustomer(widget.customer.id);
  }

  Future<void> _makeCall() async {
    final uri = Uri.parse('tel:${widget.customer.phone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp() async {
    final phone = widget.customer.phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendReminder() async {
    final customer = context.read<CustomerProvider>().selectedCustomer;
    if (customer != null && customer.pendingAmount > 0) {
      await ShareService.sendSmsReminder(
        customer.phone,
        customer.pendingAmount,
      );
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${widget.customer.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context
                  .read<CustomerProvider>()
                  .deleteCustomer(widget.customer.id);
              if (mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          final customer = provider.selectedCustomer ?? widget.customer;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                // Custom App Bar with Customer Info
                SliverAppBar(
                  expandedHeight: 280,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        // Navigate to edit screen
                      },
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'delete') {
                          _showDeleteDialog();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: AppTheme.errorColor),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Avatar
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    customer.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Name
                              Text(
                                customer.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Phone
                              Text(
                                customer.phone,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildActionButton(
                                    icon: Icons.phone,
                                    label: 'Call',
                                    onTap: _makeCall,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildActionButton(
                                    icon: Icons.message,
                                    label: 'WhatsApp',
                                    onTap: _sendWhatsApp,
                                  ),
                                  if (customer.pendingAmount > 0) ...[
                                    const SizedBox(width: 16),
                                    _buildActionButton(
                                      icon: Icons.notifications_active,
                                      label: 'Remind',
                                      onTap: _sendReminder,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Stats Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Purchase',
                            value: currencyFormat.format(customer.totalPurchase),
                            color: AppTheme.successColor,
                            icon: Icons.shopping_cart_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Pending Amount',
                            value: currencyFormat.format(customer.pendingAmount),
                            color: customer.pendingAmount > 0
                                ? AppTheme.errorColor
                                : AppTheme.successColor,
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Collect Payment Button (if pending)
                if (customer.pendingAmount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: CustomButton(
                        text: 'Collect Payment',
                        icon: Icons.payments_outlined,
                        backgroundColor: AppTheme.successColor,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaymentScreen(customer: customer),
                            ),
                          ).then((_) => _loadCustomerData());
                        },
                      ),
                    ),
                  ),

                // Tab Bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryColor,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primaryColor,
                      tabs: const [
                        Tab(text: 'All Bills'),
                        Tab(text: 'Pending Bills'),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // All Bills Tab
                _buildBillsList(provider.customerBills),
                // Pending Bills Tab
                _buildBillsList(
                  provider.customerBills
                      .where((b) => b.status != AppConstants.billPaid)
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillsList(List bills) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bills found',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BillCard(
            bill: bill,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BillDetailScreen(billId: bill.id),
                ),
              ).then((_) => _loadCustomerData());
            },
          ),
        );
      },
    );
  }
}

// Helper delegate for sticky tab bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}