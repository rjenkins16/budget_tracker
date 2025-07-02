class Transaction {
  final String name;
  final double amount;
  final DateTime date;
  final bool isIncome;

  Transaction({
    required this.name,
    required this.amount,
    required this.date,
    required this.isIncome,
  });
}

class Account {
  final String name;
  double balance;
  final List<Transaction> transactions;

  Account({
    required this.name,
    required this.balance,
    List<Transaction>? transactions,
  }) : transactions = transactions ?? [];

  void addTransaction(Transaction tx) {
    transactions.add(tx);
    balance += tx.isIncome ? tx.amount : -tx.amount;
  }

  double getMonthlyIncome(int year, int month) {
    return transactions
        .where((tx) => tx.isIncome && tx.date.year == year && tx.date.month == month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getMonthlyExpenses(int year, int month) {
    return transactions
        .where((tx) => !tx.isIncome && tx.date.year == year && tx.date.month == month)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getYearlyIncome(int year) {
    return transactions
        .where((tx) => tx.isIncome && tx.date.year == year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double getYearlyExpenses(int year) {
    return transactions
        .where((tx) => !tx.isIncome && tx.date.year == year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}
