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
  final String? userEmail;
  final int? userId;
  final String? error;
  final bool isLoading;

  const AuthState({
    this.isLoggedIn = false,
    this.userName,
    this.userEmail,
    this.userId,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? userName,
    String? userEmail,
    int? userId,
    String? error,
    bool? isLoading,
  }) =>
      AuthState(
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        userName: userName ?? this.userName,
        userEmail: userEmail ?? this.userEmail,
        userId: userId ?? this.userId,
        error: error,
        isLoading: isLoading ?? this.isLoading,
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

    // Try API token first
    if (_api.hasToken) {
      try {
        // Restore user info from local session
        final localUser = await _local.getCurrentUser();
        if (localUser != null) {
          state = AuthState(
            isLoggedIn: true,
            userName: localUser['name'] as String?,
            userEmail: localUser['email'] as String?,
            userId: localUser['id'] as int?,
          );
        }
        // Sync data from API
        await _syncAfterAuth();
        if (localUser != null) {
          state = state.copyWith(isLoading: false);
        } else {
          // Token exists but no local session — token was set before local session saving was added.
          // Clear it and fall through to local session (or logout if none).
          await _api.clearToken();
          await _local.clearCurrentUser();
        }
        return;
      } catch (_) {
        // Token invalid or API unavailable — clear and fall through
        await _api.clearToken();
      }
    }

    // Fall back to local session (offline mode)
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
        userEmail: localUser['email'] as String?,
        userId: localUser['id'] as int?,
      );
    }
  }

  /// After login/register, sync all data from API to local storage
  Future<void> _syncAfterAuth() async {
    await Future.wait([
      _ref.read(accountsProvider.notifier).syncFromApi(),
      _ref.read(customersProvider.notifier).syncFromApi(),
      _ref.read(transactionsProvider.notifier).syncFromApi(),
      _ref.read(chequesProvider.notifier).syncFromApi(),
      _ref.read(chequeBooksProvider.notifier).syncFromApi(),
    ]);
  }

  /// Save user session to local storage so init() can restore it
  Future<void> _saveLocalSession(Map<String, dynamic> user) async {
    await _local.setString('current_user_email', user['email'] as String);
    await _local.setString('current_user_name', user['name'] as String);
    await _local.setInt('current_user_id', user['id'] as int);
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.register(name, email, password);
      final user = response['user'] as Map<String, dynamic>;

      // Save user to local session so init() can restore info
      await _saveLocalSession(user);

      await _syncAfterAuth();
      state = AuthState(
        isLoggedIn: true,
        userName: user['name'] as String?,
        userEmail: user['email'] as String?,
        userId: user['id'] as int?,
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

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _api.login(email, password);
      final user = response['user'] as Map<String, dynamic>;

      // Save user to local session so init() can restore info
      await _saveLocalSession(user);

      await _syncAfterAuth();
      state = AuthState(
        isLoggedIn: true,
        userName: user['name'] as String?,
        userEmail: user['email'] as String?,
        userId: user['id'] as int?,
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

  Future<void> logout() async {
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
