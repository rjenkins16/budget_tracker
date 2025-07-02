import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:window_size/window_size.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/account.dart';
import '../models/AccountManager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AccountManager accountManager;
  Map<String, List<Map<String, dynamic>>> calendar = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeWindow();
    loadData();
  }

  void initializeWindow() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setWindowMaxSize(Size.infinite);
        setWindowMinSize(const Size(800, 600));
        getCurrentScreen().then((screen) {
          if (screen != null) {
            final frame = screen.visibleFrame;
            // Fallback to explicit Rect construction
            setWindowFrame(Rect.fromLTWH(
              frame.left,
              frame.top,
              frame.width,
              frame.height,
            ));
          }
        });
      });
    }
  }

  Future<void> loadData() async {
    accountManager = AccountManager();
    accountManager.accounts.addAll([
      Account(name: "Checking", balance: 2281.34),
      Account(name: "Savings", balance: 3000.00),
      Account(name: "Cash", balance: 150.00),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    double totalBalance = accountManager.totalBalance();
    double monthlyIncome = accountManager.totalMonthlyIncome(DateTime.now().year, DateTime.now().month);
    double yearlyIncome = accountManager.totalYearlyIncome(DateTime.now().year);
    double monthlyExpenses = accountManager.totalMonthlyExpenses(DateTime.now().year, DateTime.now().month);
    double yearlyExpenses = accountManager.totalYearlyExpenses(DateTime.now().year);

    return Scaffold(
      appBar: AppBar(title: const Text('My Finances')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Accounts", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxCardWidth = 220;
                  int crossAxisCount = (constraints.maxWidth / (maxCardWidth + 14)).floor();
                  crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      ...accountManager.accounts.map((acc) {
                        return GestureDetector(
                          onLongPress: () => _showDeleteAccountDialog(acc),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 220),
                            child: Card(
                              elevation: 2,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(acc.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium!
                                            .copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    Text("\$${acc.balance.toStringAsFixed(2)}",
                                        style: Theme.of(context).textTheme.headlineSmall),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: _showAddAccountDialog,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 220),
                          child: Card(
                            elevation: 2,
                            color: Colors.teal.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, size: 40, color: Colors.teal),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text("Summary", style: Theme.of(context).textTheme.titleLarge),
            Card(
              child: ListTile(
                title: const Text("Total Balance"),
                trailing: Text("\$${totalBalance.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Monthly Income"),
                trailing: Text("\$${monthlyIncome.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Yearly Income"),
                trailing: Text("\$${yearlyIncome.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Monthly Expenses"),
                trailing: Text("\$${monthlyExpenses.toStringAsFixed(2)}"),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text("Yearly Expenses"),
                trailing: Text("\$${yearlyExpenses.toStringAsFixed(2)}"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Account"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Account Name"),
            ),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Initial Balance"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final balance = double.tryParse(balanceController.text.trim()) ?? 0.0;
              if (name.isNotEmpty) {
                setState(() {
                  accountManager.accounts.add(Account(name: name, balance: balance));
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(Account account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete ${account.name}?"),
        content: const Text("Are you sure you want to delete this account?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                accountManager.accounts.remove(account);
              });
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
