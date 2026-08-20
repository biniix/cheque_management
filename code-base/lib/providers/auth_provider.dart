import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/local_store.dart';
import 'accounts_provider.dart';
import 'customers_provider.dart';
import 'transactions_provider.dart';
import 'cheques_provider.dart';
import 'cheque_books_provider.dart';

class AuthState {
  final bool isLoggedIn;
  final String? userName;
  final String? employeeId;
  final int? userId;
  final String? role;
  final List<String> moduleAccess;
  final String? error;
  final bool isLoading;

  final bool mustChangePassword;

  const AuthState({
    this.isLoggedIn = false,
    this.userName,
    this.employeeId,
    this.userId,
    this.role,
    this.moduleAccess = const [],
    this.error,
    this.isLoading = false,
    this.mustChangePassword = false,
  });

  bool get isAdmin => role == 'admin';

  bool canAccess(String module) => isAdmin || moduleAccess.contains(module);

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? employeeId,
    int? userId,
    String? role,
    List<String>? moduleAccess,
    String? error,
    bool? isLoading,
    bool? mustChangePassword,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userName: userName ?? this.userName,
        employeeId: employeeId ?? this.employeeId,
        userId: userId ?? this.userId,
        role: role ?? this.role,
        moduleAccess: moduleAccess ?? this.moduleAccess,
        error: error,
        isLoading: isLoading ?? this.isLoading,
        mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      );

  AuthState clearError() => copyWith(error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final LocalStore _local;
  final Ref _ref;

  AuthNotifier(this._api, this._local, this._ref) : super(const AuthState());

  Future<void> init() async {
    await _api.init();

    if (_api.hasToken) {
      try {

        final localUser = await _local.getCurrentUser();
        if (localUser != null) {
          state = AuthState(
            isLoggedIn: true,
            userName: localUser['name'] as String?,
            employeeId: localUser['employee_id'] as String?,
            userId: localUser['id'] as int?,
            role: localUser['role'] as String?,
            moduleAccess: _parseModules(localUser['module_access']),
            mustChangePassword:
                localUser['must_change_password'] == true,
          );
        }

        await _syncAfterAuth();
        if (localUser != null) {
          state = state.copyWith(isLoading: false);
        } else {

          await _api.clearToken();
          await _local.clearCurrentUser();
        }
        return;
      } catch (_) {

        await _api.clearToken();
      }
    }

    final localUser = await _local.getCurrentUser();
    if (localUser != null) {
      await _ref.read(accountsProvider.notifier).load();
      await _ref.read(customersProvider.notifier).load();
      await _ref.read(transactionsProvider.notifier).load();
      await _ref.read(chequesProvider.notifier).load();
      await _ref.read(chequeBooksProvider.notifier).load();
      state = AuthState(
        isLoggedIn: true,
        userName: localUser['name'] as String?,
        employeeId: localUser['employee_id'] as String?,
        userId: localUser['id'] as int?,
        role: localUser['role'] as String?,
        moduleAccess: _parseModules(localUser['module_access']),
        mustChangePassword:
            localUser['must_change_password'] == true,
      );
    }
  }

  static List<String> _parseModules(dynamic raw) {
    if (raw is List) return raw.map((m) => m.toString()).toList();
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = raw.trim().startsWith('[')
            ? (jsonDecode(raw) as List)
            : raw.split(',');
        return decoded.map((m) => m.toString().trim()).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<void> _syncAfterAuth() async {
    await Future.wait([
      _ref.read(accountsProvider.notifier).syncFromApi(),
      _ref.read(customersProvider.notifier).syncFromApi(),
      _ref.read(transactionsProvider.notifier).syncFromApi(),
      _ref.read(chequesProvider.notifier).syncFromApi(),
      _ref.read(chequeBooksProvider.notifier).syncFromApi(),
    ]);
  }

  Future<void> _saveLocalSession(Map<String, dynamic> user) async {
    await _local.setString('current_user_employee_id', user['employee_id'] as String);
    await _local.setString('current_user_name', user['name'] as String);
    await _local.setInt('current_user_id', user['id'] as int);
    await _local.setString('current_user_role', user['role'] as String? ?? 'employee');
    await _local.setString('current_user_modules',
        (user['module_access'] as List?)?.join(',') ?? '');
    final mustChange =
        user['must_change_password'] == true || user['must_change_password'] == 1;
    await _local.setBool('current_user_must_change', mustChange);
  }

  Future<bool> login(String employeeId, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.login(employeeId, password);
      final user = response['user'] as Map<String, dynamic>;

      await _saveLocalSession(user);

      await _syncAfterAuth();
      state = AuthState(
        isLoggedIn: true,
        userName: user['name'] as String?,
        employeeId: user['employee_id'] as String?,
        userId: user['id'] as int?,
        role: user['role'] as String?,
        moduleAccess: _parseModules(user['module_access']),
        mustChangePassword:
            user['must_change_password'] == true || user['must_change_password'] == 1,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:
            'Cannot reach the server. Make sure the backend API is running.');
      return false;
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _api.changePassword(oldPassword, newPassword);
    await _local.setBool('current_user_must_change', false);
    state = state.copyWith(mustChangePassword: false);
  }

  Future<void> logout() async {

    try {
      await _api.logout();
    } catch (_) {

    }
    await _api.clearToken();
    await _local.clearCurrentUser();
    state = const AuthState();
  }

  void clearError() {
    state = state.clearError();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ApiService();
  final local = LocalStore();
  return AuthNotifier(api, local, ref);
});
