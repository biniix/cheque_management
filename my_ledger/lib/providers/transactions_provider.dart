import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/local_store.dart';

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final LocalStore _store;

  TransactionsNotifier(this._store) : super([]);

  Future<void> load() async {
    final jsonList = await _store.getAll('transactions');
    state = jsonList.map((j) => Transaction.fromJson(j)).toList();
  }

  Future<int> addTransaction(Transaction transaction) async {
    final json = transaction.toJson();
    json.remove('id');
    final id = await _store.nextId('transactions');
    json['id'] = id;
    final newTx = Transaction.fromJson(json);
    state = [newTx, ...state];
    await _store.saveList('transactions', state.map((t) => t.toJson()).toList());
    return id;
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
