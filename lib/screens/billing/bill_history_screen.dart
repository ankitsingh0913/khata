import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bill_provider.dart';
import '../../Config/app_theme.dart';
import '../../widgets/bill_card.dart';
import 'bill_details_screen.dart';

class BillHistoryScreen extends StatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<BillProvider>().loadBills();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Bill History'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Paid'),
            Tab(text: 'Pending'),
          ],
        ),
      ),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allBills = provider.bills;
          final paidBills = allBills.where((b) => b.isPaid).toList();
          final pendingBills = allBills.where((b) => !b.isPaid).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBillsList(allBills),
              _buildBillsList(paidBills),
              _buildBillsList(pendingBills),
            ],
          );
        },
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

    return RefreshIndicator(
      onRefresh: () => context.read<BillProvider>().loadBills(),
      child: ListView.builder(
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}