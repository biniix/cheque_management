import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audit_log.dart';
import '../services/api_service.dart';

class AuditLogsNotifier extends StateNotifier<List<AuditLog>> {
  final ApiService _api = ApiService();

  AuditLogsNotifier() : super([]);

  Future<bool> load({
    int limit = 300,
    String? action,
    String? entity,
    int? entityId,
    String? query,
  }) async {
    try {
      final logs = await _api.getAuditLogs(
        limit: limit,
        action: action,
        entity: entity,
        entityId: entityId,
        query: query,
      );
      state = logs.map((j) => AuditLog.fromJson(j)).toList();
      return true;
    } catch (_) {

      return false;
    }
  }
}

final auditLogsProvider =
    StateNotifierProvider<AuditLogsNotifier, List<AuditLog>>((ref) {
  return AuditLogsNotifier();
});
