import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cheque_design.dart';
import '../services/api_service.dart';

class ChequeDesignsNotifier extends StateNotifier<List<ChequeDesign>> {
  final ApiService _api = ApiService();

  ChequeDesignsNotifier() : super([]);

  /// Load all cheque design templates from the API.
  Future<void> load() async {
    try {
      final designs = await _api.getChequeDesigns();
      state = designs.map((j) => ChequeDesign.fromJson(j)).toList();
    } catch (_) {
      // Offline / not logged in — keep current state (empty => default design)
    }
  }

}

/// Resolve the design for a bank from a loaded list of templates.
/// A denomination-specific template wins over the bank-wide ('') template.
/// Use with `ref.watch(chequeDesignsProvider)` so the leaf rebuilds when the
/// templates finish loading.
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
