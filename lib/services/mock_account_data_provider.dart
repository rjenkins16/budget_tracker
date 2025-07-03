// lib/services/mock_account_data_provider.dart
import 'dart:async';
import '../models/account.dart';
import 'account_data_provider.dart';

class MockAccountDataProvider implements AccountDataProvider {
  @override
  Future<List<Account>> fetchAccounts() async {
    return [
      Account(name: "Checking", balance: 2281.34),
      Account(name: "Savings", balance: 3000.00),
      Account(name: "Cash", balance: 150.00),
    ];
  }

  @override
  Future<void> syncAccountTransactions(Account account) async {
    // Simulate pulling in some transactions later
    return;
  }
}
