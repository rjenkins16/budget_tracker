import '../models/account.dart';

abstract class AccountDataProvider {
  Future<List<Account>> fetchAccounts();
  Future<void> syncAccountTransactions(Account account);
}
