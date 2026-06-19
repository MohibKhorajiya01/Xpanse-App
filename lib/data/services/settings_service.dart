import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final settingsServiceProvider = ChangeNotifierProvider((ref) => SettingsService());

class SettingsService extends ChangeNotifier {
  final _box = Hive.box('settings');

  String get currency => _box.get('currency', defaultValue: 'INR (₹)');
  String get currencySymbol => currency.split('(').last.replaceAll(')', '').trim();

  Future<void> setCurrency(String value) async {
    await _box.put('currency', value);
    notifyListeners();
  }
}
