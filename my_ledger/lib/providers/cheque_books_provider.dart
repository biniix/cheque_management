import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque_book.dart';
import '../services/local_store.dart';

class ChequeBooksNotifier extends StateNotifier<List<ChequeBook>> {
  final LocalStore _store;

  ChequeBooksNotifier(this._store) : super([]);

  Future<void> load() async {
    final jsonList = await _store.getAll('cheque_books');
    state = jsonList.map((j) => ChequeBook.fromJson(j)).toList();
  }

  Future<int> addChequeBook(ChequeBook book) async {
    final json = book.toJson();
    json.remove('id');
    final id = await _store.nextId('cheque_books');
    json['id'] = id;
    final newBook = ChequeBook.fromJson(json);
    state = [...state, newBook];
    await _store.saveList('cheque_books', state.map((b) => b.toJson()).toList());
    return id;
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
