import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque.dart' show Cheque;
import '../services/local_store.dart';
import '../services/api_service.dart';

class ChequeAddResult {
  final int chequeId;
  final Map<String, dynamic>? transactionData;
  final double? newBalance;

  ChequeAddResult({
    required this.chequeId,
    this.transactionData,
    this.newBalance,
  });
}

class ChequesNotifier extends StateNotifier<List<Cheque>> {
  final LocalStore _store;
  final ApiService _api = ApiService();

  ChequesNotifier(this._store) : super([]);

  Future<void> load() async {
    try {
      final jsonList = await _store.getAll('cheques');
      state = jsonList.map((j) => Cheque.fromJson(j)).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> syncFromApi() async {
    try {
      final apiCheques = await _api.getCheques();
      await _store.saveList('cheques', apiCheques);
      state = apiCheques.map((j) => Cheque.fromJson(j)).toList();
    } catch (_) {
      await load();
    }
  }

  Future<ChequeAddResult> addCheque(Cheque cheque) async {
    final json = cheque.toJson();
    json.remove('id');
    json.remove('transaction_id'); // Let the API generate this

    Map<String, dynamic>? transactionData;
    double? newBalance;

    try {
      final apiResult = await _api.writeCheque(json);
      final apiCheque = apiResult['data']?['cheque'] as Map<String, dynamic>?;
      transactionData = apiResult['data']?['transaction'] as Map<String, dynamic>?;
      newBalance = (apiResult['data']?['newBalance'] as num?)?.toDouble();

      if (apiCheque != null && apiCheque['id'] != null) {
        json['id'] = apiCheque['id'];
        if (apiCheque['transaction_id'] != null) {
          json['transaction_id'] = apiCheque['transaction_id'];
        }
        if (apiCheque['created_at'] != null) json['created_at'] = apiCheque['created_at'];
        if (apiCheque['updated_at'] != null) json['updated_at'] = apiCheque['updated_at'];
      }
    } catch (_) {

      json['id'] = await _store.nextId('cheques');
    }

    final newCheque = Cheque.fromJson(json);
    state = [...state, newCheque];
    await _store.saveList('cheques', state.map((c) => c.toJson()).toList());
    return ChequeAddResult(
      chequeId: json['id'] as int,
      transactionData: transactionData,
      newBalance: newBalance,
    );
  }

  Future<void> updateStatus(int id, String status) async {

    try {
      await _api.updateChequeStatus(id, status);
    } catch (_) {

    }

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
