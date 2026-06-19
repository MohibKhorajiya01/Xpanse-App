import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

// provider that gives read access to other providers
final transactionRepositoryProvider = Provider((ref) => TransactionRepository(ref));

// Streams to let UI update in real time
final transactionsStreamProvider = StreamProvider<List<Transaction>>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchTransactions();
});

class TransactionRepository {
  final Ref _ref;
  final Box<Transaction> _box = Hive.box<Transaction>('transactions');

  TransactionRepository(this._ref);

  List<Transaction> getAllTransactions() {
    return _box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Stream<List<Transaction>> watchTransactions() {
    return _box.watch().map((_) => getAllTransactions());
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);

    // try saving to cloud if user logged in
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).saveTransaction(user.uid, transaction);
      } catch (_) {}
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    await _box.put(transaction.id, transaction);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).saveTransaction(user.uid, transaction);
      } catch (_) {}
    }
  }

  Future<void> deleteTransaction(String id) async {
    await _box.delete(id);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).deleteTransaction(user.uid, id);
      } catch (_) {}
    }
  }

  double getTotalBalance({String? walletId}) {
    double total = 0;
    for (var t in _box.values) {
      if (walletId != null && t.walletId != walletId) continue;
      if (t.isIncome) {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
  }

  double getIncomeSummary({String? walletId}) {
    return _box.values
        .where((t) => t.isIncome && (walletId == null || t.walletId == walletId))
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getExpenseSummary({String? walletId}) {
    return _box.values
        .where((t) => !t.isIncome && (walletId == null || t.walletId == walletId))
        .fold(0, (sum, t) => sum + t.amount);
  }

  List<Map<String, double>> getDailyCandleData({String? walletId}) {
    final transactions = getAllTransactions()
        .where((t) => walletId == null || t.walletId == walletId)
        .toList()
        .reversed
        .toList();
    
    // We want to show a 7-day window ending today
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 6));
    
    // Calculate balance BEFORE the 7-day window starts
    double runningBalance = 0;
    for (var t in _box.values) {
      if (walletId != null && t.walletId != walletId) continue;
      if (t.date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
        if (t.isIncome) {
          runningBalance += t.amount;
        } else {
          runningBalance -= t.amount;
        }
      }
    }

    final Map<String, List<Transaction>> grouped = {};
    for (var t in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(dateKey, () => []).add(t);
    }

    List<Map<String, double>> candleData = [];

    // Iterate through EVERY day in the last 7 days
    for (int i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      
      double open = runningBalance;
      double high = runningBalance;
      double low = runningBalance;
      
      if (grouped.containsKey(dateKey)) {
        for (var tx in grouped[dateKey]!) {
          if (tx.isIncome) {
            runningBalance += tx.amount;
          } else {
            runningBalance -= tx.amount;
          }
          if (runningBalance > high) high = runningBalance;
          if (runningBalance < low) low = runningBalance;
        }
      }
      
      double close = runningBalance;
      candleData.add({
        'open': open,
        'high': high,
        'low': low,
        'close': close,
      });
    }

    return candleData;
  }
}
