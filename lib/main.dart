import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khata/providers/auth_provider.dart';
import 'package:khata/providers/bill_provider.dart';
import 'package:khata/providers/customer_provider.dart';
import 'package:khata/providers/dashboard_provider.dart';
import 'package:khata/providers/product_provider.dart';
import 'package:khata/services/database_service.dart';
import 'package:provider/provider.dart';

import 'Config/app_theme.dart';
import 'Screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await DatabaseService.instance.database;

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => BillProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Shopkeeper',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}