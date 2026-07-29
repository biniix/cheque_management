import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/account.dart';
import '../services/local_store.dart';
import '../services/api_service.dart';

class AccountsNotifier extends StateNotifier<List<Account>> {
  final LocalStore _store;
  final ApiService _api = ApiService();

  AccountsNotifier(this._store) : super([]);

  /// Load from local storage (fast, offline-first)
  Future<void> load() async {
    final jsonList = await _store.getAll('accounts');
    state = jsonList.map((j) => Account.fromJson(j)).toList();
  }

  /// Sync accounts from API server into local storage
  Future<void> syncFromApi() async {
    try {
      final apiAccounts = await _api.getAccounts();
      if (apiAccounts.isNotEmpty) {
        await _store.saveList('accounts', apiAccounts);
        state = apiAccounts.map((j) => Account.fromJson(j)).toList();
      }
    } catch (_) {
      // API unavailable — just use local data
      await load();
    }
  }

  /// Save to BOTH API server and local storage
  Future<void> addAccount(Account account) async {
    final json = account.toJson();
    json.remove('id');

    // Try saving to API first (source of truth for ID)
    try {
      final apiResult = await _api.createAccount(json);
      if (apiResult['id'] != null) {
        json['id'] = apiResult['id'];
        if (apiResult['created_at'] != null) json['created_at'] = apiResult['created_at'];
        if (apiResult['updated_at'] != null) json['updated_at'] = apiResult['updated_at'];
      }
    } catch (_) {
      // API unavailable — use local auto-increment ID
      json['id'] = await _store.nextId('accounts');
    }

    final newAccount = Account.fromJson(json);
    final updatedList = [...state, newAccount];
    await _store.saveList('accounts', updatedList.map((a) => a.toJson()).toList());
    state = updatedList;
  }

  Future<void> updateAccount(Account account) async {
    // Try updating on API
    try {
      await _api.updateAccount(account.id, account.toJson());
    } catch (_) {}

    final updatedList = state.map((a) => a.id == account.id ? account : a).toList();
    await _store.saveList('accounts', updatedList.map((a) => a.toJson()).toList());
    state = updatedList;
  }

  Future<void> deleteAccount(int id) async {
    // Try deleting from API
    try {
      await _api.deleteAccount(id);
    } catch (_) {}

    final updatedList = state.where((a) => a.id != id).toList();
    await _store.saveList('accounts', updatedList.map((a) => a.toJson()).toList());
    state = updatedList;
  }

  Future<void> toggleVisibility(int id) async {
    final updatedList = state.map((a) {
      if (a.id == id) return a.copyWith(isVisible: !a.isVisible);
      return a;
    }).toList();
    await _store.saveList('accounts', updatedList.map((a) => a.toJson()).toList());
    state = updatedList;
  }

  Future<void> updateBalance(int id, double newBalance) async {
    final updatedList = state.map((a) {
      if (a.id == id) return a.copyWith(balance: newBalance);
      return a;
    }).toList();
    await _store.saveList('accounts', updatedList.map((a) => a.toJson()).toList());
    state = updatedList;
  }

  double get totalBalance =>
      state.fold(0.0, (sum, a) => sum + a.balance);

  List<Account> get visibleAccounts => state.where((a) => a.isVisible).toList();
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, List<Account>>((ref) {
  final store = LocalStore();
  return AccountsNotifier(store);
});
