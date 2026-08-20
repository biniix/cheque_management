import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque_design.dart';
import '../services/api_service.dart';

class ChequeDesignsNotifier extends StateNotifier<List<ChequeDesign>> {
  final ApiService _api = ApiService();

  ChequeDesignsNotifier() : super([]);

  Future<void> load() async {
    try {
      final designs = await _api.getChequeDesigns();
      state = designs.map((j) => ChequeDesign.fromJson(j)).toList();
    } catch (_) {

    }
  }

}

ChequeDesign? designForBank(
  List<ChequeDesign> designs,
  String bankKey, {
  String denomination = '',
}) {
  if (bankKey.isEmpty) return null;
  for (final d in designs) {
    if (d.bankKey == bankKey && d.denomination == denomination) return d;
  }
  for (final d in designs) {
    if (d.bankKey == bankKey && d.denomination.isEmpty) return d;
  }
  return null;
}

final chequeDesignsProvider =
    StateNotifierProvider<ChequeDesignsNotifier, List<ChequeDesign>>((ref) {
  return ChequeDesignsNotifier();
});
