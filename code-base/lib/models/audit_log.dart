/// A single activity/audit log entry, matching the `/audit-logs` API response.
class AuditLog {
  final int id;
  final int? userId;
  final String userName;
  final String employeeId;
  final String action; // login | login_failed | logout | create | update | delete | password_change | status_change
  final String entityType; // auth | employee | account | customer | transaction | transfer | cheque | chequebook
  final int? entityId;
  final String details;
  final String ipAddress;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    this.userId,
    this.userName = '',
    this.employeeId = '',
    this.action = '',
    this.entityType = '',
    this.entityId,
    this.details = '',
    this.ipAddress = '',
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as int,
        userId: json['user_id'] as int?,
        userName: json['user_name'] as String? ?? '',
        employeeId: json['employee_id'] as String? ?? '',
        action: json['action'] as String? ?? '',
        entityType: json['entity_type'] as String? ?? '',
        entityId: json['entity_id'] as int?,
        details: json['details'] as String? ?? '',
        ipAddress: json['ip_address'] as String? ?? '',
        createdAt: json['created_at'] != null
            ? (DateTime.tryParse(json['created_at'] as String) ?? DateTime.now())
            : DateTime.now(),
      );

  /// Human-friendly label for the action, e.g. "Password change".
  String get actionLabel {
    switch (action) {
      case 'login':
        return 'Login';
      case 'login_failed':
        return 'Failed login';
      case 'logout':
        return 'Logout';
      case 'create':
        return 'Created';
      case 'update':
        return 'Updated';
      case 'delete':
        return 'Deleted';
      case 'password_change':
        return 'Password change';
      case 'status_change':
        return 'Status change';
      default:
        return action.isEmpty ? 'Activity' : action;
    }
  }

  /// Human-friendly label for the entity type, e.g. "Cheque book".
  String get entityLabel {
    switch (entityType) {
      case 'auth':
        return 'Account';
      case 'employee':
        return 'Employee';
      case 'account':
        return 'Bank account';
      case 'customer':
        return 'Customer';
      case 'transaction':
        return 'Transaction';
      case 'transfer':
        return 'Transfer';
      case 'cheque':
        return 'Cheque';
      case 'chequebook':
        return 'Cheque book';
      default:
        return entityType.isEmpty ? 'Activity' : entityType;
    }
  }
}
