import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  bool _hasLinkedAccounts = false;
  List<dynamic> _accounts = [];
  List<dynamic> _transactions = [];

  double _totalBalance = 0;
  double _income = 0;
  double _expenses = 0;

  // Change this to match your backend
  final String backendBaseUrl = "http://localhost:5050";

  @override
  void initState() {
    super.initState();
    _fetchAccountsAndTransactions();
  }

  Future<void> _fetchAccountsAndTransactions() async {
    try {
      final accountsRes = await http.get(Uri.parse('$backendBaseUrl/accounts'));
      if (accountsRes.statusCode == 200) {
        final data = jsonDecode(accountsRes.body);
        final accounts = data['accounts'] ?? [];
        setState(() {
          _accounts = accounts;
          _hasLinkedAccounts = accounts.isNotEmpty;
          _totalBalance = accounts.fold(
            0.0,
            (sum, acc) => sum + (acc['balance'] ?? 0),
          );
        });
      }

      if (_hasLinkedAccounts) {
        final txRes = await http.get(Uri.parse('$backendBaseUrl/transactions'));
        if (txRes.statusCode == 200) {
          final txData = jsonDecode(txRes.body) as List<dynamic>;

          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final endOfMonth = DateTime(now.year, now.month + 1, 0);

          double income = 0;
          double expenses = 0;

          for (var tx in txData) {
            final date = DateTime.tryParse(tx['date'] ?? '');
            if (date == null) continue;
            if (date.isBefore(startOfMonth) || date.isAfter(endOfMonth)) continue;

            final amt = (tx['amount'] as num).toDouble();
            final category = tx['category']?.toString().toLowerCase() ?? "";

            // Classify
            if (category.contains('income') || category.contains('deposit')) {
              income += amt;
            } else if (!category.contains('transfer')) {
              expenses += amt;
            }
          }

          setState(() {
            _transactions = txData;
            _income = income;
            _expenses = expenses;
          });
        }
      }
    } catch (e) {
      print("Error fetching dashboard data: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _linkPlaidAccount() async {
    final url = Uri.parse('$backendBaseUrl/plaid/link');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Plaid link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brown = const Color(0xFF6B4F4F);
    final lightBrown = const Color(0xFFD9B382);
    final greenAccent = const Color(0xFF5C8A64);

    if (_loading) {
      return Scaffold(
        backgroundColor: lightBrown.withOpacity(0.1),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasLinkedAccounts) {
      return Scaffold(
        backgroundColor: lightBrown.withOpacity(0.1),
        body: Center(
          child: ElevatedButton(
            onPressed: _linkPlaidAccount,
            style: ElevatedButton.styleFrom(
              backgroundColor: brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Link Your Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    final double netIncome = _income - _expenses;
    final double budgetLimit = 2000; // Replace with your own logic
    final double budgetProgress =
        (_expenses / budgetLimit).clamp(0.0, 1.0); // Cap at 100%

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: brown,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchAccountsAndTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCard(
                title: "Total Balance",
                value:
                    "\$${_totalBalance.toStringAsFixed(2)}",
                color: greenAccent,
              ),
              const SizedBox(height: 16),
              _buildIncomeExpenseRow(),
              const SizedBox(height: 16),
              _buildBudgetHealth(budgetProgress, brown, greenAccent),
              const SizedBox(height: 24),
              Text(
                "Recent Transactions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),
              const SizedBox(height: 8),
              ..._transactions.take(5).map((tx) {
                final isExpense = (tx['amount'] as num) > 0;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    tx['name'],
                    style: TextStyle(
                      color: brown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(tx['date']),
                  trailing: Text(
                    "${isExpense ? '-' : '+'}\$${tx['amount'].abs().toStringAsFixed(2)}",
                    style: TextStyle(
                      color: isExpense ? Colors.redAccent : greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required String value, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              )),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeExpenseRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 1,
          child: _buildCard(
            title: "Income",
            value: "\$${_income.toStringAsFixed(2)}",
            color: const Color(0xFF5C8A64),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          flex: 1,
          child: _buildCard(
            title: "Expenses",
            value: "\$${_expenses.toStringAsFixed(2)}",
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetHealth(double progress, Color brown, Color green) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: brown.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brown.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Budget Health",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: brown,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: brown.withOpacity(0.2),
            color: green,
          ),
          const SizedBox(height: 8),
          Text(
            "${(progress * 100).toStringAsFixed(0)}% of budget used",
            style: TextStyle(color: brown.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}
