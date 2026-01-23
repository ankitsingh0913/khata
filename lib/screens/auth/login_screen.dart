import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().login(
      phone: _phoneController.text,
      shopName: _shopNameController.text,
      ownerName: _ownerNameController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Logo
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Welcome to Smart Shopkeeper',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Setup your shop to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Shop Name
                CustomTextField(
                  label: 'Shop Name',
                  hint: 'Enter your shop name',
                  controller: _shopNameController,
                  prefixIcon: const Icon(Icons.store_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shop name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Owner Name
                CustomTextField(
                  label: 'Owner Name',
                  hint: 'Enter your name',
                  controller: _ownerNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter owner name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Number
                CustomTextField(
                  label: 'Phone Number',
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
                const SizedBox(height: 40),

                // Login Button
                CustomButton(
                  text: 'Get Started',
                  isLoading: _isLoading,
                  onPressed: _handleLogin,
                  icon: Icons.arrow_forward_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}