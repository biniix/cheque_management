import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for communicating with the My Ledger API backend.
/// Handles JWT auth tokens and all CRUD operations.
class ApiService {
  // Change this to your API server URL
  static const String baseUrl = 'http://localhost:3000/api';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('api_token');
  }

  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_token');
  }

  bool get hasToken => _token != null;
  String? get token => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> _get(String path, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.get(uri, headers: withAuth ? _headers : {'Content-Type': 'application/json'});
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {bool withAuth = true}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.post(uri, headers: withAuth ? _headers : {'Content-Type': 'application/json'}, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.put(uri, headers: _headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.patch(uri, headers: _headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await http.delete(uri, headers: _headers);
    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) as Map<String, dynamic> : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      body['message'] as String? ?? 'Request failed (${response.statusCode})',
      response.statusCode,
    );
  }

  // ── Auth ──
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('/auth/login', {'email': email, 'password': password}, withAuth: false);
    await _saveToken(response['token'] as String);
    return response;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await _post('/auth/register', {'name': name, 'email': email, 'password': password}, withAuth: false);
    await _saveToken(response['token'] as String);
    return response;
  }

  // ── Accounts ──
  Future<List<Map<String, dynamic>>> getAccounts() async {
    final response = await _get('/accounts');
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createAccount(Map<String, dynamic> account) async {
    final response = await _post('/accounts', account);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAccount(int id, Map<String, dynamic> data) async {
    final response = await _put('/accounts/$id', data);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteAccount(int id) async {
    await _delete('/accounts/$id');
  }

  // ── Customers ──
  Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await _get('/customers');
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createCustomer(Map<String, dynamic> customer) async {
    final response = await _post('/customers', customer);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCustomer(int id, Map<String, dynamic> data) async {
    final response = await _put('/customers/$id', data);
    return response['data'] as Map<String, dynamic>;
  }

  Future<void> deleteCustomer(int id) async {
    await _delete('/customers/$id');
  }

  // ── Transactions ──
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final accounts = await getAccounts();
    final allTransactions = <Map<String, dynamic>>[];
    for (final acc in accounts) {
      final response = await _get('/accounts/${acc['id']}');
      final data = response['data'] as Map<String, dynamic>;
      final txs = data['transactions'] as List<dynamic>? ?? [];
      for (final tx in txs) {
        (tx as Map<String, dynamic>)['account_id'] = acc['id'];
        allTransactions.add(tx);
      }
    }
    return allTransactions;
  }

  // ── Cheques ──
  Future<List<Map<String, dynamic>>> getCheques() async {
    final response = await _get('/cheques');
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getChequeBooks() async {
    final response = await _get('/cheques/books');
    return (response['data'] as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createChequeBook(Map<String, dynamic> book) async {
    final response = await _post('/cheques/books', book);
    return response['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> writeCheque(Map<String, dynamic> cheque) async {
    final response = await _post('/cheques', cheque);
    return response;
  }

  Future<Map<String, dynamic>> updateChequeStatus(int id, String status) async {
    final response = await _patch('/cheques/$id/status', {'status': status});
    return response['data'] as Map<String, dynamic>;
  }

  // ── Transfers ──
  Future<Map<String, dynamic>> recordTransfer(Map<String, dynamic> transfer) async {
    return await _post('/transfers', transfer);
  }

  // ── Dashboard ──
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _get('/dashboard');
    return response['data'] as Map<String, dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => 'ApiException($statusCode): $message';
}
