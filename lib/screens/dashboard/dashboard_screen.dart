import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/customer_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../widgets/set_card.dart';
import '../../widgets/bill_card.dart';
import '../customers/customer_list_screen.dart';
import '../products/product_list_screen.dart';
import '../billing/create_bill_screen.dart';
import '../billing/bill_history_screen.dart';
import '../loans/loan_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<DashboardProvider>().loadDashboard(),
      context.read<CustomerProvider>().loadCustomers(),
      context.read<ProductProvider>().loadProducts(),
      context.read<BillProvider>().loadBills(limit: 10),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          const CustomerListScreen(),
          const CreateBillScreen(),
          const ProductListScreen(),
          _buildSettingsTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          setState(() => _currentIndex = 2);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Bill'),
      ) : null,
    );
  }

  Widget _buildHomeTab() {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Consumer<DashboardProvider>(
      builder: (context, dashboard, _) {
        final auth = context.watch<AuthProvider>();

        return RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.backgroundColor,
                elevation: 0,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.shopName ?? 'My Shop',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Welcome back, ${auth.ownerName ?? 'User'}!',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {},
                  ),
                ],
              ),

              // Stats Cards
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildListDelegate([
                    StatCard(
                      title: "Today's Sales",
                      value: currencyFormat.format(dashboard.todaySales),
                      icon: Icons.trending_up_rounded,
                      color: AppTheme.successColor,
                      subtitle: '${dashboard.todayBillCount} bills',
                    ),
                    StatCard(
                      title: 'Monthly Sales',
                      value: currencyFormat.format(dashboard.monthlySales),
                      icon: Icons.calendar_month_rounded,
                      color: AppTheme.primaryColor,
                      subtitle: '${dashboard.monthlyBillCount} bills',
                    ),
                    StatCard(
                      title: 'Total Pending',
                      value: currencyFormat.format(dashboard.totalPending),
                      icon: Icons.account_balance_wallet_outlined,
                      color: AppTheme.errorColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoanDashboardScreen()),
                        );
                      },
                    ),
                    StatCard(
                      title: 'Low Stock',
                      value: '${dashboard.lowStockCount}',
                      icon: Icons.inventory_2_outlined,
                      color: AppTheme.warningColor,
                      subtitle: 'items',
                    ),
                  ]),
                ),
              ),

              // Quick Actions
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQuickAction(
                            icon: Icons.person_add_outlined,
                            label: 'Add Customer',
                            color: AppTheme.primaryColor,
                            onTap: () {
                              setState(() => _currentIndex = 1);
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            icon: Icons.inventory_2_outlined,
                            label: 'Add Product',
                            color: AppTheme.accentColor,
                            onTap: () {
                              setState(() => _currentIndex = 3);
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            icon: Icons.history_rounded,
                            label: 'Bill History',
                            color: AppTheme.secondaryColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const BillHistoryScreen()),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildQuickAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Dues',
                            color: AppTheme.errorColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoanDashboardScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Recent Bills
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Bills',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BillHistoryScreen()),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),

              Consumer<BillProvider>(
                builder: (context, billProvider, _) {
                  if (billProvider.isLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (billProvider.bills.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 80,
                              color: AppTheme.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No bills yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create your first bill',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final bill = billProvider.bills[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: BillCard(
                              bill: bill,
                              onTap: () {
                                // Navigate to bill detail
                              },
                            ),
                          );
                        },
                        childCount: billProvider.bills.take(5).length,
                      ),
                    ),
                  );
                },
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shop Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.store,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.shopName ?? 'My Shop',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        auth.ownerName ?? 'Owner',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      Text(
                        auth.phone ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings Items
          _buildSettingsItem(
            icon: Icons.backup_outlined,
            title: 'Backup Data',
            subtitle: 'Backup your data to cloud',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.download_outlined,
            title: 'Export Data',
            subtitle: 'Export data to Excel/CSV',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.print_outlined,
            title: 'Print Settings',
            subtitle: 'Configure printer settings',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and info',
            onTap: () {},
          ),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from this device',
            onTap: () async {
              await auth.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    return Container(
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
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people_rounded),
            label: 'customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_shopping_cart_outlined),
            activeIcon: Icon(Icons.add_shopping_cart_rounded),
            label: 'Bill',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2_rounded),
            label: 'products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}