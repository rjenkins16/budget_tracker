import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class AccountDataProvider {
  Future<List<Account>> fetchAccounts() async {
    final baseUrl = dotenv.env['PLAID_BACKEND_BASE_URL']!;
    final response = await http.get(Uri.parse('$baseUrl/accounts'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      final List<dynamic> data = json['accounts'] ?? [];
      return data.map((accJson) => Account.fromJson(accJson)).toList();
    } else {
      throw Exception('Failed to fetch accounts: ${response.body}');
    }
  }

  Future<void> syncAccountTransactions(Account account) async {
    final baseUrl = dotenv.env['PLAID_BACKEND_BASE_URL']!;
    final response = await http.post(
      Uri.parse('$baseUrl/transactions/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'account_id': account.id}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to sync transactions: ${response.body}');
    }
  }

  Future<void> addAccount(Account account) async {
    final baseUrl = dotenv.env['PLAID_BACKEND_BASE_URL']!;
    final response = await http.post(
      Uri.parse('$baseUrl/accounts/link'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to link account: ${response.body}');
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final baseUrl = dotenv.env['PLAID_BACKEND_BASE_URL']!;
    final response = await http.delete(
      Uri.parse('$baseUrl/accounts/$accountId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete account: ${response.body}');
    }
  }

  Future<List<Transaction>> fetchTransactions(Account account) async {
    final baseUrl = dotenv.env['PLAID_BACKEND_BASE_URL']!;
    final response = await http.get(
      Uri.parse('$baseUrl/accounts/${account.id}/transactions'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((txJson) => Transaction.fromJson(txJson)).toList();
    } else {
      throw Exception('Failed to fetch transactions: ${response.body}');
    }
  }
}
