import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Generic local persistence service backed by SharedPreferences.
/// Each entity type has its own key and an auto-incrementing ID counter.
class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  // ── Generic list helpers ──

  Future<List<Map<String, dynamic>>> getList(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);
      if (stored == null) return [];
      final List<dynamic> decoded = jsonDecode(stored) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('LocalStore.getList($key) error: $e');
      return [];
    }
  }

  Future<void> saveList(String key, List<Map<String, dynamic>> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(items));
    } catch (e) {
      debugPrint('LocalStore.saveList($key) error: $e');
    }
  }

  // ── Auto-incrementing IDs ──

  Future<int> nextId(String entityType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${entityType}_next_id';
    final current = prefs.getInt(key) ?? 1;
    await prefs.setInt(key, current + 1);
    return current;
  }

  // ── Entity CRUD helpers ──

  Future<List<Map<String, dynamic>>> getAll(String entityKey) async {
    return getList(entityKey);
  }

  Future<Map<String, dynamic>?> getById(String entityKey, int id) async {
    final items = await getList(entityKey);
    try {
      return items.firstWhere((item) => item['id'] == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> insert(String entityKey, Map<String, dynamic> item) async {
    final items = await getList(entityKey);
    final id = await nextId(entityKey);
    item['id'] = id;
    items.add(item);
    await saveList(entityKey, items);
    return id;
  }

  Future<void> update(String entityKey, int id, Map<String, dynamic> item) async {
    final items = await getList(entityKey);
    final index = items.indexWhere((i) => i['id'] == id);
    if (index != -1) {
      item['id'] = id;
      items[index] = item;
      await saveList(entityKey, items);
    }
  }

  Future<void> delete(String entityKey, int id) async {
    final items = await getList(entityKey);
    items.removeWhere((i) => i['id'] == id);
    await saveList(entityKey, items);
  }

  // ── Persisted key-value helpers (for visibility toggles, etc.) ──

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  // ── Local Auth ──

  /// Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  /// Register a new user locally (store in SharedPreferences)
  Future<Map<String, dynamic>> registerUser(
      String name, String email, String password) async {
    final users = await getList('users');
    // Check if email already exists
    final existing = users.where((u) => u['email'] == email).toList();
    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    final id = await nextId('users');
    final user = {
      'id': id,
      'name': name,
      'email': email,
      'password_hash': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    };
    users.add(user);
    await saveList('users', users);

    // Save current session
    await setString('current_user_email', email);
    await setString('current_user_name', name);
    await setInt('current_user_id', id);

    return {'id': id, 'name': name, 'email': email};
  }

  /// Login a user locally
  Future<Map<String, dynamic>> loginUser(
      String email, String password) async {
    final users = await getList('users');
    final hashed = _hashPassword(password);

    final match = users.where(
        (u) => u['email'] == email && u['password_hash'] == hashed).toList();
    if (match.isEmpty) {
      throw Exception('Invalid email or password.');
    }

    final user = match.first;
    // Save current session
    await setString('current_user_email', email);
    await setString('current_user_name', user['name'] as String);
    await setInt('current_user_id', user['id'] as int);

    return {'id': user['id'], 'name': user['name'], 'email': user['email']};
  }

  /// Check if a local user session exists
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final email = await getString('current_user_email');
    final name = await getString('current_user_name');
    final id = await getInt('current_user_id');
    if (email != null && name != null && id != null) {
      return {'id': id, 'name': name, 'email': email};
    }
    return null;
  }

  /// Clear the current user session
  Future<void> clearCurrentUser() async {
    await remove('current_user_email');
    await remove('current_user_name');
    await remove('current_user_id');
  }

  // ── Helpers ──

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  // ── Clear all app data ──

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      'accounts',
      'customers',
      'transactions',
      'cheque_books',
      'cheques',
      'users',
    ];
    for (final key in keys) {
      await prefs.remove(key);
      await prefs.remove('${key}_next_id');
    }
    await clearCurrentUser();
  }
}
