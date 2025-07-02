

import 'account.dart';

class AccountManager {
  List<Account> accounts = [];

  double totalBalance() =>
      accounts.fold(0.0, (sum, acc) => sum + acc.balance);

  double totalMonthlyIncome(int year, int month) =>
      accounts.fold(0.0, (sum, acc) => sum + acc.getMonthlyIncome(year, month));

  double totalYearlyIncome(int year) =>
      accounts.fold(0.0, (sum, acc) => sum + acc.getYearlyIncome(year));

  double totalMonthlyExpenses(int year, int month) =>
      accounts.fold(0.0, (sum, acc) => sum + acc.getMonthlyExpenses(year, month));

  double totalYearlyExpenses(int year) =>
      accounts.fold(0.0, (sum, acc) => sum + acc.getYearlyExpenses(year));
}
