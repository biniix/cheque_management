import 'dart:convert';

class Employee {
  final int id;
  final String name;
  final String employeeId;
  final String role; // 'admin' | 'employee'
  final String position;
  final bool isActive;
  final List<String> moduleAccess;
  final DateTime createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.employeeId,
    this.role = 'employee',
    this.position = '',
    this.isActive = true,
    this.moduleAccess = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => role == 'admin';

  bool canAccess(String module) => isAdmin || moduleAccess.contains(module);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'employee_id': employeeId,
        'role': role,
        'position': position,
        'is_active': isActive,
        'module_access': moduleAccess,
        'created_at': createdAt.toIso8601String(),
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawModules = json['module_access'];
    List<String> modules = [];
    if (rawModules is List) {
      modules = rawModules.map((m) => m.toString()).toList();
    } else if (rawModules is String && rawModules.trim().isNotEmpty) {
      final text = rawModules.trim();
      try {
        final parsed = text.startsWith('[')
            ? (jsonDecode(text) as List)
            : text.split(',');
        modules = parsed.map((m) => m.toString().trim()).toList();
      } catch (_) {
        modules = [];
      }
    }
    return Employee(
      id: json['id'] as int,
      name: json['name'] as String,
      employeeId: json['employee_id'] as String? ?? '',
      role: json['role'] as String? ?? 'employee',
      position: json['position'] as String? ?? '',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      moduleAccess: modules,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Employee copyWith({
    String? name,
    String? position,
    bool? isActive,
    List<String>? moduleAccess,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        employeeId: employeeId,
        role: role,
        position: position ?? this.position,
        isActive: isActive ?? this.isActive,
        moduleAccess: moduleAccess ?? this.moduleAccess,
        createdAt: createdAt,
      );
}
