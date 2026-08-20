import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque_book.dart' show ChequeBook;
import '../services/local_store.dart';
import '../services/api_service.dart';

class ChequeBooksNotifier extends StateNotifier<List<ChequeBook>> {
  final LocalStore _store;
  final ApiService _api = ApiService();

  ChequeBooksNotifier(this._store) : super([]);

  Future<void> load() async {
    try {
      final jsonList = await _store.getAll('cheque_books');
      state = jsonList.map((j) => ChequeBook.fromJson(j)).toList();
    } catch (_) {
      state = [];
    }
  }

  Future<void> syncFromApi() async {
    try {
      final apiBooks = await _api.getChequeBooks();
      await _store.saveList('cheque_books', apiBooks);
      state = apiBooks.map((j) => ChequeBook.fromJson(j)).toList();
    } catch (_) {
      await load();
    }
  }

  Future<int> addChequeBook(ChequeBook book) async {
    final json = book.toJson();
    json.remove('id');

    try {
      final apiBook = await _api.createChequeBook(json);
      if (apiBook['id'] != null) {
        json['id'] = apiBook['id'];
        if (apiBook['created_at'] != null) json['created_at'] = apiBook['created_at'];
      }
    } catch (_) {

      json['id'] = await _store.nextId('cheque_books');
    }

    final newBook = ChequeBook.fromJson(json);
    state = [...state, newBook];
    await _store.saveList('cheque_books', state.map((b) => b.toJson()).toList());
    return json['id'] as int;
  }

  List<ChequeBook> getForAccount(int accountId) {
    return state.where((b) => b.accountId == accountId).toList();
  }
}

final chequeBooksProvider =
    StateNotifierProvider<ChequeBooksNotifier, List<ChequeBook>>((ref) {
  final store = LocalStore();
  return ChequeBooksNotifier(store);
});
