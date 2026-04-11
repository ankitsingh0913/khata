import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:khata/providers/customer_provider.dart';
import 'package:khata/config/app_theme.dart';
import 'package:khata/widgets/custom_text_field.dart';
import 'package:khata/widgets/customer_card.dart';
import 'package:khata/screens/customers/add_customer_screen.dart';
import 'package:khata/screens/customers/customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<CustomerProvider>().loadCustomers();
    });
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddCustomer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
    );

    // reload after adding customer
    if (mounted) {
      context.read<CustomerProvider>().loadCustomers();
    }
  }

  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: _openAddCustomer,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              hint: 'Search customers...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                context.read<CustomerProvider>().searchCustomers(value);
              },
            ),
          ),

          // Customer List
          Expanded(
            child: Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.customers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No customers yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _openAddCustomer,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Customer'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadCustomers(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.customers.length,
                    itemBuilder: (context, index) {
                      final customer = provider.customers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomerCard(
                          customer: customer,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CustomerDetailScreen(customer: customer),
                              ),
                            );
                          },
                          onCall: () => _makeCall(customer.phone),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}