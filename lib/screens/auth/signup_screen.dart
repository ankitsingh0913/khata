import 'package:flutter/material.dart';
import 'package:khata/Screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../dashboard/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await context.read<AuthProvider>().signup(
      shopName: _shopNameController.text,
      ownerName: _ownerNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
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

                const Center(
                  child: Text(
                    'Create your account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                CustomTextField(
                  label: 'Shop Name',
                  hint: 'Enter your shop name',
                  controller: _shopNameController,
                  prefixIcon: const Icon(Icons.store_outlined),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Owner Name',
                  hint: 'Enter owner name',
                  controller: _ownerNameController,
                  prefixIcon: const Icon(Icons.person_outline),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Email',
                  hint: 'Enter email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),

                const SizedBox(height: 20),

                CustomTextField(
                  label: 'Password',
                  hint: 'Enter password',
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                ),

                const SizedBox(height: 40),

                CustomButton(
                  text: "Create Account",
                  isLoading: _isLoading,
                  onPressed: _handleSignup,
                  icon: Icons.arrow_forward_rounded,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                      );;
                    },
                    child: const Text("Already have an account? Login"),
                  ),
                )

              ],
            ),
          ),
        ),
      ),
    );
  }
}