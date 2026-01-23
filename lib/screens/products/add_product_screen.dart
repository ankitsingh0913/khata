import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // For editing

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _lowStockAlertController = TextEditingController();

  String _selectedUnit = 'pcs';
  bool _isLoading = false;

  final List<String> _units = ['pcs', 'kg', 'g', 'ltr', 'ml', 'box', 'pack', 'dozen'];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.product!;
      _nameController.text = p.name;
      _descriptionController.text = p.description ?? '';
      _categoryController.text = p.category ?? '';
      _barcodeController.text = p.barcode ?? '';
      _purchasePriceController.text = p.purchasePrice.toString();
      _sellingPriceController.text = p.sellingPrice.toString();
      _stockController.text = p.stock.toString();
      _lowStockAlertController.text = p.lowStockAlert.toString();
      _selectedUnit = p.unit;
    } else {
      _stockController.text = '0';
      _lowStockAlertController.text = '10';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _lowStockAlertController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = context.read<ProductProvider>();

    bool success;
    if (isEditing) {
      final updatedProduct = widget.product!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stock: int.parse(_stockController.text),
        lowStockAlert: int.parse(_lowStockAlertController.text),
        unit: _selectedUnit,
      );
      success = await provider.updateProduct(updatedProduct);
    } else {
      final product = await provider.addProduct(
        name: _nameController.text,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        category: _categoryController.text.isNotEmpty ? _categoryController.text : null,
        barcode: _barcodeController.text.isNotEmpty ? _barcodeController.text : null,
        purchasePrice: double.parse(_purchasePriceController.text),
        sellingPrice: double.parse(_sellingPriceController.text),
        stock: int.parse(_stockController.text),
        lowStockAlert: int.parse(_lowStockAlertController.text),
        unit: _selectedUnit,
      );
      success = product != null;
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Product updated successfully!' : 'Product added successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: AppTheme.accentColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              CustomTextField(
                label: 'Product Name *',
                hint: 'Enter product name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.shopping_bag_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              CustomTextField(
                label: 'Category',
                hint: 'Enter category (e.g., Grocery, Electronics)',
                controller: _categoryController,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              const SizedBox(height: 16),

              // Barcode
              CustomTextField(
                label: 'Barcode/SKU',
                hint: 'Enter barcode or SKU',
                controller: _barcodeController,
                prefixIcon: const Icon(Icons.qr_code),
              ),
              const SizedBox(height: 16),

              // Prices Row
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Purchase Price *',
                      hint: '0.00',
                      controller: _purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.money_outlined),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'Selling Price *',
                      hint: '0.00',
                      controller: _sellingPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.sell_outlined),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stock and Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Stock *',
                      hint: '0',
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.inventory_outlined),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              isExpanded: true,
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => _selectedUnit = value!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Low Stock Alert
              CustomTextField(
                label: 'Low Stock Alert',
                hint: '10',
                controller: _lowStockAlertController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.warning_amber_outlined),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
              ),
              const SizedBox(height: 16),

              // Description
              CustomTextField(
                label: 'Description',
                hint: 'Enter product description',
                controller: _descriptionController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: isEditing ? 'Update Product' : 'Add Product',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}