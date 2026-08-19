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

  /// Sync transactions from API server into local storage.
  Future<void> syncFromApi() async {
    try {
      final apiTransactions = await _api.getTransactions();
      await _store.saveList('transactions', apiTransactions);
      state = apiTransactions.map((j) => Transaction.fromJson(j)).toList();
    } catch (_) {
      await load();
    }
  }

  /// Add a transaction that was already created on the API server (e.g. by writing a cheque).
  /// This saves it to local state WITHOUT making another API call.
  Future<void> addTransactionFromApi(Map<String, dynamic> txData) async {
    final tx = Transaction.fromJson(txData);
    // Remove from state if it already exists (deduplication)
    state = state.where((t) => t.id != tx.id).toList();
    state = [tx, ...state];
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
  }

  Future<int> addTransaction(Transaction transaction) async {
    final json = transaction.toJson();
    json.remove('id');

    // Try saving to API first (source of truth for ID)
    try {
      final apiResult = await _api.createTransaction(json);
      if (apiResult['id'] != null) {
        json['id'] = apiResult['id'];
        if (apiResult['created_at'] != null) json['created_at'] = apiResult['created_at'];
      }
    } catch (_) {
      // API unavailable — use local auto-increment ID
      json['id'] = await _store.nextId('transactions');
    }

    final newTx = Transaction.fromJson(json);
    state = [newTx, ...state];
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    return json['id'] as int;
  }

  /// Edit an existing transaction — syncs the change to the API (which also
  /// adjusts the account balance) and updates local state.
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
      // API unavailable — apply locally only
      state = state.map((t) => t.id == transaction.id ? transaction : t).toList();
      await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    }
  }

  /// Delete a transaction — syncs to the API (which reverses the balance)
  /// and removes it from local state.
  Future<void> deleteTransaction(int id) async {
    try {
      await _api.deleteTransaction(id);
    } catch (_) {
      // API unavailable — delete locally only
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
