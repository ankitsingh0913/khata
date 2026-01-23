// lib/screens/loans/loan_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import '../../config/app_theme.dart';
import '../../config/app_constants.dart';
import '../../widgets/customer_card.dart';
import '../customers/customer_detail_screen.dart';

class LoanDashboardScreen extends StatefulWidget {
  const LoanDashboardScreen({super.key});

  @override
  State<LoanDashboardScreen> createState() => _LoanDashboardScreenState();
}

class _LoanDashboardScreenState extends State<LoanDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomerProvider>().loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Dues / Udhaar'),
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final customersWithDues = provider.customersWithDues;
          final totalPending = provider.totalPendingAmount;

          return Column(
            children: [
              // Total Pending Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.errorColor, Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.errorColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Pending Amount',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalPending),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${customersWithDues.length} customers with dues',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Customers with Dues
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'customers with Dues',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${customersWithDues.length}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Customer List
              Expanded(
                child: customersWithDues.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 40,
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No pending dues!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All customers have cleared their payments',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: () => provider.loadCustomers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: customersWithDues.length,
                    itemBuilder: (context, index) {
                      final customer = customersWithDues[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomerCard(
                          customer: customer,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CustomerDetailScreen(customer: customer),
                              ),
                            ).then((_) => provider.loadCustomers());
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}