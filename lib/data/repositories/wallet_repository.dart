import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/wallet.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

final walletRepositoryProvider = Provider((ref) => WalletRepository(ref));

final walletsStreamProvider = StreamProvider<List<Wallet>>((ref) async* {
  final box = Hive.box<Wallet>('wallets');
  yield box.values.toList();
  await for (final _ in box.watch()) {
    yield box.values.toList();
  }
});

class WalletRepository {
  final Ref _ref;
  final Box<Wallet> _box = Hive.box<Wallet>('wallets');

  WalletRepository(this._ref);

  List<Wallet> getAllWallets() {
    return _box.values.toList();
  }

  Future<void> addWallet(Wallet wallet) async {
    await _box.put(wallet.id, wallet);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).saveWallet(user.uid, wallet);
      } catch (_) {}
    }
  }

  Future<void> deleteWallet(String id) async {
    await _box.delete(id);
    final user = _ref.read(authServiceProvider).currentUser;
    if (user != null) {
      try {
        await _ref.read(firestoreServiceProvider).deleteWallet(user.uid, id);
      } catch (_) {}
    }
  }

  Future<void> seedDefaultWallets({bool force = false}) async {
    final defaults = [
      Wallet(id: 'wallet_main', name: 'Main Wallet', balance: 0, iconCodepoint: 0xe69e, colorValue: 0xFF6366F1),
      Wallet(id: 'wallet_bank', name: 'Bank Account', balance: 0, iconCodepoint: 0xe0a6, colorValue: 0xFF10B981),
      Wallet(id: 'wallet_cash', name: 'Cash', balance: 0, iconCodepoint: 0xef1e, colorValue: 0xFFF59E0B),
      Wallet(id: 'wallet_savings', name: 'Savings', balance: 0, iconCodepoint: 0xe42c, colorValue: 0xFF10B981),
    ];

    if (force) {
      await _box.clear();
      for (var w in defaults) {
        await _box.put(w.id, w);
      }
      return;
    }

    for (var w in defaults) {
      if (!_box.containsKey(w.id)) {
        await _box.put(w.id, w);
      }
    }
  }
}
