import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer.dart';
import '../services/local_store.dart';
import '../services/api_service.dart';

class CustomersNotifier extends StateNotifier<List<Customer>> {
  final LocalStore _store;
  final ApiService _api = ApiService();

  CustomersNotifier(this._store) : super([]);

  Future<void> load() async {
    final jsonList = await _store.getAll('customers');
    state = jsonList.map((j) => Customer.fromJson(j)).toList();
  }

  /// Sync customers from API server into local storage
  Future<void> syncFromApi() async {
    try {
      final apiCustomers = await _api.getCustomers();
      if (apiCustomers.isNotEmpty) {
        await _store.saveList('customers', apiCustomers);
        state = apiCustomers.map((j) => Customer.fromJson(j)).toList();
      }
    } catch (_) {
      await load();
    }
  }

  Future<void> addCustomer(Customer customer) async {
    final json = customer.toJson();
    json.remove('id');

    // Try API first
    try {
      final apiResult = await _api.createCustomer(json);
      if (apiResult['id'] != null) {
        json['id'] = apiResult['id'];
        if (apiResult['created_at'] != null) json['created_at'] = apiResult['created_at'];
      }
    } catch (_) {
      json['id'] = await _store.nextId('customers');
    }

    final newCustomer = Customer.fromJson(json);
    final updatedList = [...state, newCustomer];
    await _store.saveList('customers', updatedList.map((c) => c.toJson()).toList());
    state = updatedList;
  }

  Future<void> updateCustomer(Customer customer) async {
    try {
      await _api.updateCustomer(customer.id, customer.toJson());
    } catch (_) {}

    final updatedList = state.map((c) => c.id == customer.id ? customer : c).toList();
    await _store.saveList('customers', updatedList.map((c) => c.toJson()).toList());
    state = updatedList;
  }

  Future<void> deleteCustomer(int id) async {
    try {
      await _api.deleteCustomer(id);
    } catch (_) {}

    final updatedList = state.where((c) => c.id != id).toList();
    await _store.saveList('customers', updatedList.map((c) => c.toJson()).toList());
    state = updatedList;
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, List<Customer>>((ref) {
  final store = LocalStore();
  return CustomersNotifier(store);
});
