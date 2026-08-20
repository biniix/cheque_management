import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/employee.dart';
import '../services/api_service.dart';

class EmployeesNotifier extends StateNotifier<List<Employee>> {
  final ApiService _api = ApiService();

  EmployeesNotifier() : super([]);

  Future<void> load() async {
    try {
      final apiEmployees = await _api.getEmployees();
      state = apiEmployees.map((j) => Employee.fromJson(j)).toList();
    } catch (_) {

    }
  }

  Future<Employee> addEmployee({
    required String name,
    required String position,
    required String password,
    required List<String> moduleAccess,
  }) async {
    final apiEmployee = await _api.createEmployee({
      'name': name,
      'position': position,
      'password': password,
      'module_access': moduleAccess,
    });
    final employee = Employee.fromJson(apiEmployee);
    state = [...state, employee];
    return employee;
  }

  Future<void> updateEmployee(
    int id, {
    String? name,
    String? position,
    String? password,
    List<String>? moduleAccess,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (position != null) data['position'] = position;
    if (password != null && password.isNotEmpty) data['password'] = password;
    if (moduleAccess != null) data['module_access'] = moduleAccess;

    try {
      final apiEmployee = await _api.updateEmployee(id, data);
      final updated = Employee.fromJson(apiEmployee);
      state = state.map((e) => e.id == id ? updated : e).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> toggleActive(int id, bool isActive) async {
    try {
      final apiEmployee = await _api.updateEmployeeStatus(id, isActive);
      final updated = Employee.fromJson(apiEmployee);
      state = state.map((e) => e.id == id ? updated : e).toList();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteEmployee(int id) async {
    try {
      await _api.deleteEmployee(id);
      state = state.where((e) => e.id != id).toList();
    } catch (_) {
      rethrow;
    }
  }
}

final employeesProvider =
    StateNotifierProvider<EmployeesNotifier, List<Employee>>((ref) {
  return EmployeesNotifier();
});
