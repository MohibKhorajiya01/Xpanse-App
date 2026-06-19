import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/category.dart';
import '../models/budget.dart';
import 'firestore_service.dart';
import '../repositories/transaction_repository.dart';
import '../repositories/wallet_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/budget_repository.dart';
import 'auth_service.dart';

final syncServiceProvider = Provider((ref) {
  final service = SyncService(
    ref.read(firestoreServiceProvider),
    ref.read(transactionRepositoryProvider),
    ref.read(walletRepositoryProvider),
    ref.read(categoryRepositoryProvider),
    ref.read(budgetRepositoryProvider),
  );

  // Correctly listen to auth state changes using AsyncValue
  ref.listen<AsyncValue<User?>>(authStateProvider, (prev, next) {
    service._handleAuthChange(next.valueOrNull);
  });

  return service;
});

class SyncService {
  final FirestoreService _fs;
  final TransactionRepository _txRepo;
  final WalletRepository _walletRepo;
  final CategoryRepository _catRepo;
  final BudgetRepository _budgetRepo;

  String? _lastUserId = FirebaseAuth.instance.currentUser?.uid;

  SyncService(
    this._fs,
    this._txRepo,
    this._walletRepo,
    this._catRepo,
    this._budgetRepo,
  );

  Future<void> _handleAuthChange(User? user) async {
    // Only clear data if actively logging out (was previously logged in)
    if (user == null) {
      if (_lastUserId != null) {
        await _clearLocalData();
        _lastUserId = null;
      }
      return;
    }

    // If changing user accounts (not guest -> logged in), clear previous user's data
    if (_lastUserId != user.uid) {
      bool isGuestMigration = (_lastUserId == null);
      if (!isGuestMigration) {
        await _clearLocalData();
      }
      await syncAll(user.uid, isMigration: isGuestMigration);
      _lastUserId = user.uid;
    }
  }

  Future<void> _clearLocalData() async {
    // Completely clear all user-specific data
    await Hive.box<Transaction>('transactions').clear();
    await Hive.box<Budget>('budgets').clear();
    
    // We clear categories and wallets and re-seed defaults so Guest mode/New user is clean
    await Hive.box<Wallet>('wallets').clear();
    await Hive.box<Category>('categories').clear();

    await _catRepo.seedDefaultCategories(force: true);
    await _walletRepo.seedDefaultWallets(force: true);
  }

  /// Sync from Cloud, only pushing local data if it's a first-time guest migration
  Future<void> syncAll(String userId, {bool isMigration = false}) async {
    if (isMigration) {
      await _pushLocal(userId);
    }
    await _pullRemote(userId);
  }

  Future<void> _pushLocal(String userId) async {
    for (var t in _txRepo.getAllTransactions()) {
      try {
        await _fs.saveTransaction(userId, t);
      } catch (_) {}
    }
    for (var w in _walletRepo.getAllWallets()) {
      try {
        await _fs.saveWallet(userId, w);
      } catch (_) {}
    }
    for (var c in _catRepo.getCategories()) {
      try {
        await _fs.saveCategory(userId, c);
      } catch (_) {}
    }
    for (var b in _budgetRepo.getAllBudgets()) {
      try {
        await _fs.saveBudget(userId, b);
      } catch (_) {}
    }
  }

  Future<void> _pullRemote(String userId) async {
    // transactions
    try {
      final cloudTxs = await _fs.fetchTransactions(userId);
      final box = Hive.box<Transaction>('transactions');
      await box.clear(); // Clear to reflect cloud deletions
      for (var t in cloudTxs) {
        await box.put(t.id, t);
      }
    } catch (_) {}

    // wallets
    try {
      final cloudW = await _fs.fetchWallets(userId);
      final box = Hive.box<Wallet>('wallets');
      await box.clear();
      if (cloudW.isEmpty) {
        await _walletRepo.seedDefaultWallets();
      } else {
        for (var w in cloudW) {
          await box.put(w.id, w);
        }
      }
    } catch (_) {}

    // categories
    try {
      final cloudC = await _fs.fetchCategories(userId);
      final box = Hive.box<Category>('categories');
      await box.clear();
      if (cloudC.isEmpty) {
        await _catRepo.seedDefaultCategories();
      } else {
        for (var c in cloudC) {
          await box.put(c.id, c);
        }
      }
    } catch (_) {}

    // budgets
    try {
      final cloudB = await _fs.fetchBudgets(userId);
      final box = Hive.box<Budget>('budgets');
      await box.clear();
      for (var b in cloudB) {
        await box.put(b.id, b);
      }
    } catch (_) {}
  }
}
