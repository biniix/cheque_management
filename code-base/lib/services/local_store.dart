import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

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

  Future<int> nextId(String entityType) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${entityType}_next_id';
    final current = prefs.getInt(key) ?? 1;
    await prefs.setInt(key, current + 1);
    return current;
  }

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

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Map<String, dynamic>> registerUser(
      String name, String employeeId, String password) async {
    final users = await getList('users');

    final existing = users.where((u) => u['employee_id'] == employeeId).toList();
    if (existing.isNotEmpty) {
      throw Exception('An account with this employee ID already exists.');
    }

    final id = await nextId('users');
    final user = {
      'id': id,
      'name': name,
      'employee_id': employeeId,
      'password_hash': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    };
    users.add(user);
    await saveList('users', users);

    await setString('current_user_employee_id', employeeId);
    await setString('current_user_name', name);
    await setInt('current_user_id', id);

    return {'id': id, 'name': name, 'employee_id': employeeId};
  }

  Future<Map<String, dynamic>> loginUser(
      String employeeId, String password) async {
    final users = await getList('users');
    final hashed = _hashPassword(password);

    final match = users.where(
        (u) => u['employee_id'] == employeeId && u['password_hash'] == hashed).toList();
    if (match.isEmpty) {
      throw Exception('Invalid employee ID or password.');
    }

    final user = match.first;

    await setString('current_user_employee_id', employeeId);
    await setString('current_user_name', user['name'] as String);
    await setInt('current_user_id', user['id'] as int);

    return {'id': user['id'], 'name': user['name'], 'employee_id': user['employee_id']};
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final employeeId = await getString('current_user_employee_id');
    final name = await getString('current_user_name');
    final id = await getInt('current_user_id');
    if (employeeId != null && name != null && id != null) {
      return {
        'id': id,
        'name': name,
        'employee_id': employeeId,
        'role': await getString('current_user_role'),
        'module_access': await getString('current_user_modules'),
        'must_change_password': await getBool('current_user_must_change'),
      };
    }
    return null;
  }

  Future<void> clearCurrentUser() async {
    await remove('current_user_employee_id');
    await remove('current_user_name');
    await remove('current_user_id');
    await remove('current_user_role');
    await remove('current_user_modules');
    await remove('current_user_must_change');
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

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
