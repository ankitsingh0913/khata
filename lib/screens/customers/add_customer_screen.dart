import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/customer_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final customer = await context.read<CustomerProvider>().addCustomer(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
    );

    setState(() => _isLoading = false);

    if (customer != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer added successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context, customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Add Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 50,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),

              // Name
              CustomTextField(
                label: 'Customer Name *',
                hint: 'Enter customer name',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              CustomTextField(
                label: 'Phone Number *',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email (Optional)
              CustomTextField(
                label: 'Email (Optional)',
                hint: 'Enter email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),

              // Address (Optional)
              CustomTextField(
                label: 'Address (Optional)',
                hint: 'Enter address',
                controller: _addressController,
                maxLines: 3,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 32),

              // Submit Button
              CustomButton(
                text: 'Add Customer',
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