import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/models/wallet.dart';
import '../models/budget.dart';
import '../models/category.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save user profile (name, email) - call on signup
  Future<void> saveUserProfile(String userId, String displayName, String email) async {
    await _db.collection('users').doc(userId).set({
      'displayName': displayName,
      'email': email,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Get user display name from Firestore - used when Firebase displayName is empty
  Future<String?> getUserDisplayName(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['displayName'] as String?;
  }

  /// Watch user profile for real-time updates
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // Save Transaction to Firestore
  Future<void> saveTransaction(String userId, Transaction transaction) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  // Delete transaction
  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(transactionId)
        .delete();
  }

  // Fetch all transactions for user
  Future<List<Transaction>> fetchTransactions(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();
    return snapshot.docs
        .map((d) => Transaction.fromMap(d.data()))
        .toList();
  }

  // Save Wallet to Firestore
  Future<void> saveWallet(String userId, Wallet wallet) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(wallet.id)
        .set(wallet.toMap());
  }

  Future<void> deleteWallet(String userId, String walletId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletId)
        .delete();
  }

  Future<List<Wallet>> fetchWallets(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .get();
    return snapshot.docs.map((d) => Wallet.fromMap(d.data())).toList();
  }

  // Categories
  Future<void> saveCategory(String userId, Category category) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(category.id)
        .set(category.toMap());
  }

  Future<void> deleteCategory(String userId, String categoryId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(categoryId)
        .delete();
  }

  Future<List<Category>> fetchCategories(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();
    return snapshot.docs.map((d) => Category.fromMap(d.data())).toList();
  }

  // Budgets
  Future<void> saveBudget(String userId, Budget budget) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budget.id)
        .set(budget.toMap());
  }

  Future<void> deleteBudget(String userId, String budgetId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(budgetId)
        .delete();
  }

  Future<List<Budget>> fetchBudgets(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .get();
    return snapshot.docs.map((d) => Budget.fromMap(d.data())).toList();
  }
}
