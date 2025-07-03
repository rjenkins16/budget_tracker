import 'package:flutter/material.dart';

class BudgetCategory {
  String category;
  double budget;
  double spent;

  BudgetCategory({
    required this.category,
    required this.budget,
    this.spent = 0.0,
  });
}

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<BudgetCategory> budgets = [
    BudgetCategory(category: 'Groceries', budget: 300.0, spent: 180.0),
    BudgetCategory(category: 'Entertainment', budget: 150.0, spent: 95.0),
    BudgetCategory(category: 'Utilities', budget: 200.0, spent: 160.0),
  ];

  void _addOrEditCategory({BudgetCategory? category, int? index}) {
    final isEditing = category != null && index != null;
    final categoryController = TextEditingController(text: isEditing ? category.category : '');
    final budgetController = TextEditingController(text: isEditing ? category.budget.toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Category' : 'Add Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Budget Amount'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newCategory = categoryController.text.trim();
                final newBudget = double.tryParse(budgetController.text.trim());
                if (newCategory.isEmpty || newBudget == null || newBudget < 0) {
                  // Invalid input, do nothing or show error
                  return;
                }
                setState(() {
                  if (isEditing) {
                    budgets[index!] = BudgetCategory(
                      category: newCategory,
                      budget: newBudget,
                      spent: budgets[index].spent,
                    );
                  } else {
                    budgets.add(BudgetCategory(category: newCategory, budget: newBudget));
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(int index) {
    setState(() {
      budgets.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalBudget = budgets.fold(0.0, (sum, item) => sum + item.budget);
    double totalSpent = budgets.fold(0.0, (sum, item) => sum + item.spent);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Budget Summary", style: Theme.of(context).textTheme.titleLarge),
            Card(child: ListTile(title: const Text("Total Budgeted"), trailing: Text("\$${totalBudget.toStringAsFixed(2)}"))),
            Card(child: ListTile(title: const Text("Total Spent"), trailing: Text("\$${totalSpent.toStringAsFixed(2)}"))),
            Card(child: ListTile(title: const Text("Remaining"), trailing: Text("\$${(totalBudget - totalSpent).toStringAsFixed(2)}"))),
            const SizedBox(height: 20),
            Text("Categories", style: Theme.of(context).textTheme.titleLarge),
            ...budgets.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final remaining = item.budget - item.spent;
              final percentUsed = item.budget > 0 ? item.spent / item.budget : 0.0;
              return Card(
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.category),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _addOrEditCategory(category: item, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCategory(index),
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: percentUsed.clamp(0.0, 1.0)),
                      const SizedBox(height: 4),
                      Text(
                        "Spent \$${item.spent.toStringAsFixed(2)} / \$${item.budget.toStringAsFixed(2)} — Remaining \$${remaining.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCategory(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
