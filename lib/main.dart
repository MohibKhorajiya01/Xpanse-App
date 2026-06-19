import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'data/models/transaction.dart';
import 'data/models/category.dart';
import 'data/models/wallet.dart';
import 'data/models/budget.dart';

import 'features/auth/presentation/screens/splash_screen.dart';
import 'data/repositories/category_repository.dart';
import 'data/repositories/wallet_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(WalletAdapter());
  Hive.registerAdapter(BudgetAdapter());
  
  // Open Boxes
  await Hive.openBox<Transaction>('transactions');
  await Hive.openBox<Category>('categories');
  await Hive.openBox<Wallet>('wallets');
  await Hive.openBox<Budget>('budgets');
  await Hive.openBox('settings');
  
  // Seed Defaults
  final container = ProviderContainer();
  await container.read(categoryRepositoryProvider).seedDefaultCategories();
  await container.read(walletRepositoryProvider).seedDefaultWallets();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const XpanseApp(),
    ),
  );
}

class XpanseApp extends StatelessWidget {
  const XpanseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xpanse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}

