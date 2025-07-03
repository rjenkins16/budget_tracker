import 'account_data_provider.dart';
import '../models/account.dart';

class PlaidAccountDataProvider implements AccountDataProvider {
  @override
  Future<List<Account>> fetchAccounts() async {
    // TODO: call your Python backend's /accounts route
    // and map Plaid data into your Account class
    return [];
  }

  @override
  Future<void> syncAccountTransactions(Account account) async {
    // TODO: hit backend /transactions endpoint, parse into your models
  }
}
