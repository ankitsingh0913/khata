import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../Config/app_constants.dart';
import '../../providers/product_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/product_card.dart';
import 'add_product_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filters {
    final categories = context.read<ProductProvider>().categories;
    return ['All', 'Low Stock', ...categories];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              hint: 'Search products...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  context.read<ProductProvider>().loadProducts();
                },
              )
                  : null,
              onChanged: (value) {
                context.read<ProductProvider>().searchProducts(value);
              },
            ),
          ),

          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondary,
                      fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Product List
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = provider.products;

                // Apply filter
                if (_selectedFilter == 'Low Stock') {
                  products = provider.lowStockProducts;
                } else if (_selectedFilter != 'All') {
                  products = provider.getProductsByCategory(_selectedFilter);
                }

                if (products.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddProductScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.loadProducts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProductCard(
                          product: product,
                          onTap: () {
                            _showProductDetails(context, product);
                          },
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProductDetails(BuildContext context, product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(product: product),
    );
  }
}

class ProductDetailSheet extends StatelessWidget {
  final dynamic product;

  const ProductDetailSheet({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
    NumberFormat.currency(symbol: AppConstants.currency, decimalDigits: 0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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

          // Product Icon
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppTheme.accentColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.category != null)
                      Text(
                        product.category!,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details Grid
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Selling Price',
                  currencyFormat.format(product.sellingPrice),
                  AppTheme.primaryColor,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Purchase Price',
                  currencyFormat.format(product.purchasePrice),
                  AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Stock',
                  '${product.stock} ${product.unit}',
                  product.isLowStock
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Profit',
                  '${currencyFormat.format(product.profit)} (${product.profitPercentage.toStringAsFixed(1)}%)',
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(product: product),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showUpdateStockDialog(context, product);
                  },
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Update Stock'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  void _showUpdateStockDialog(BuildContext context, product) {
    final controller = TextEditingController();
    bool isAdding = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Add'),
                      value: true,
                      groupValue: isAdding,
                      onChanged: (value) => setState(() => isAdding = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Remove'),
                      value: false,
                      groupValue: isAdding,
                      onChanged: (value) => setState(() => isAdding = value!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  suffixText: product.unit,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;
                if (qty > 0) {
                  await context.read<ProductProvider>().updateStock(
                    product.id,
                    qty,
                    isDeduct: !isAdding,
                  );
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}