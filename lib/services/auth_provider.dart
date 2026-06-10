import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  void _setLoading(bool v) { _loading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true); _setError(null);
    try {
      final data = await ApiService.register(fullName: fullName, email: email, password: password);
      _user = data;
      await ApiService.saveToken(data['accessToken']);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true); _setError(null);
    try {
      final data = await ApiService.login(email: email, password: password);
      _user = data;
      await ApiService.saveToken(data['accessToken']);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loginBypass({String? email, String? fullName}) async {
    _setLoading(true); _setError(null);
    try {
      final targetEmail = email ?? 'mock_user@example.com';
      final token = 'mock_token_$targetEmail';
      _user = {
        'id': 'mock_id_123',
        'email': targetEmail,
        'fullName': fullName ?? 'Mock User',
        'role': 'user',
        'accessToken': token,
      };
      await ApiService.saveToken(token);
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> socialLogin({
    required String provider,
    required String token,
    required String mode,
  }) async {
    _setLoading(true); _setError(null);
    try {
      final data = await ApiService.socialLogin(
        provider: provider,
        token: token,
        mode: mode,
      );
      _user = data;
      await ApiService.saveToken(data['accessToken']);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    final token = await ApiService.getToken();
    if (token == null) return false;
    _setLoading(true); _setError(null);
    try {
      if (token.startsWith('mock_token_')) {
        final email = token.replaceFirst('mock_token_', '');
        _user = {
          'id': 'mock_id_123',
          'email': email,
          'fullName': email.split('@')[0].toUpperCase(),
          'role': 'user',
          'accessToken': token,
        };
        notifyListeners();
        return true;
      } else {
        final userData = await ApiService.getCurrentUser();
        _user = {
          ...userData,
          'accessToken': token,
        };
        notifyListeners();
        return true;
      }
    } catch (e) {
      await ApiService.clearToken();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }
}
