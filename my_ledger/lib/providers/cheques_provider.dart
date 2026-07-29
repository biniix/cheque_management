import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque.dart';
import '../services/local_store.dart';

class ChequesNotifier extends StateNotifier<List<Cheque>> {
  final LocalStore _store;

  ChequesNotifier(this._store) : super([]);

  Future<void> load() async {
    final jsonList = await _store.getAll('cheques');
    state = jsonList.map((j) => Cheque.fromJson(j)).toList();
  }

  Future<int> addCheque(Cheque cheque) async {
    final json = cheque.toJson();
    json.remove('id');
    final id = await _store.nextId('cheques');
    json['id'] = id;
    final newCheque = Cheque.fromJson(json);
    state = [...state, newCheque];
    await _store.saveList('cheques', state.map((c) => c.toJson()).toList());
    return id;
  }

  Future<void> updateStatus(int id, String status) async {
    final updatedList = state.map((c) {
      if (c.id == id) return c.copyWith(status: status);
      return c;
    }).toList();
    await _store.saveList('cheques', updatedList.map((c) => c.toJson()).toList());
    state = updatedList;
  }

  Future<void> updateCheque(Cheque cheque) async {
    final updatedList = state.map((c) => c.id == cheque.id ? cheque : c).toList();
    await _store.saveList('cheques', updatedList.map((c) => c.toJson()).toList());
    state = updatedList;
  }

  /// Get the next unused cheque number for a cheque book
  Future<String> getNextNumber(int chequebookId, String startNumber) async {
    final chequesForBook = state.where((c) => c.chequebookId == chequebookId).toList();
    final usedCount = chequesForBook.length;
    final start = int.parse(startNumber);
    final nextNum = start + usedCount;
    return nextNum.toString().padLeft(startNumber.length, '0');
  }

  List<Cheque> getForAccount(List<int> accountIds) {
    return state.where((c) => c.chequebookId == 0 || accountIds.contains(c.chequebookId)).toList();
  }

  List<Cheque> getForChequeBook(int chequebookId) {
    return state.where((c) => c.chequebookId == chequebookId).toList();
  }

  List<Cheque> getFiltered({int? accountId, String? status, List<int>? bookIds}) {
    var filtered = state;
    if (status != null && status != 'all') {
      filtered = filtered.where((c) => c.status == status).toList();
    }
    return filtered;
  }

  /// Check stale cheques and update their status
  void checkStaleCheques() {
    final updatedList = state.map((c) {
      if (c.isStale && c.status != 'Void' && c.status != 'Cleared') {
        return c.copyWith(status: 'Stale');
      }
      return c;
    }).toList();
    final changed = updatedList.any((c) => c.status == 'Stale');
    if (changed) {
      state = updatedList;
      _store.saveList('cheques', updatedList.map((c) => c.toJson()).toList());
    }
  }
}

final chequesProvider = StateNotifierProvider<ChequesNotifier, List<Cheque>>((ref) {
  final store = LocalStore();
  return ChequesNotifier(store);
});
