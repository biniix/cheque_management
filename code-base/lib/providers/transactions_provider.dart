import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart' show Transaction;
import '../services/local_store.dart';
import '../services/api_service.dart';

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final LocalStore _store;
  final ApiService _api = ApiService();

  TransactionsNotifier(this._store) : super([]);

  Future<void> load() async {
    try {
      final jsonList = await _store.getAll('transactions');
      state = jsonList.map((j) => Transaction.fromJson(j)).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> syncFromApi() async {
    try {
      final apiTransactions = await _api.getTransactions();
      await _store.saveList('transactions', apiTransactions);
      state = apiTransactions.map((j) => Transaction.fromJson(j)).toList();
    } catch (_) {
      await load();
    }
  }

  Future<void> addTransactionFromApi(Map<String, dynamic> txData) async {
    final tx = Transaction.fromJson(txData);

    state = state.where((t) => t.id != tx.id).toList();
    state = [tx, ...state];
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
  }

  Future<int> addTransaction(Transaction transaction) async {
    final json = transaction.toJson();
    json.remove('id');

    try {
      final apiResult = await _api.createTransaction(json);
      if (apiResult['id'] != null) {
        json['id'] = apiResult['id'];
        if (apiResult['created_at'] != null) json['created_at'] = apiResult['created_at'];
      }
    } catch (_) {

      json['id'] = await _store.nextId('transactions');
    }

    final newTx = Transaction.fromJson(json);
    state = [newTx, ...state];
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    return json['id'] as int;
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final json = transaction.toJson();
    json.remove('id');
    json.remove('account_id');
    json.remove('reference_no');
    json.remove('created_at');

    try {
      final apiResult = await _api.updateTransaction(transaction.id, json);
      final updated = Transaction.fromJson(apiResult);
      state = state.map((t) => t.id == updated.id ? updated : t).toList();
      await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    } catch (_) {

      state = state.map((t) => t.id == transaction.id ? transaction : t).toList();
      await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await _api.deleteTransaction(id);
    } catch (_) {

    }
    state = state.where((t) => t.id != id).toList();
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
  }

  List<Transaction> getForAccount(int accountId) {
    return state.where((t) => t.accountId == accountId).toList();
  }

  List<Transaction> getRecent(int count) {
    final sorted = List<Transaction>.from(state)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(count).toList();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final store = LocalStore();
  return TransactionsNotifier(store);
});
