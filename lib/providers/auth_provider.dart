import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/api_client.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();

  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> initAuth() async {
    _setLoading(true);

    try {
      await _api.loadToken();
      if (!_api.hasToken) {
        _currentUser = null;
        _setLoading(false);
        return;
      }

      final data = await _api.get('/auth/me');
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Init auth error: $e');
      await _api.clearToken();
      _currentUser = null;
    }

    _setLoading(false);
  }

  Future<String?> register(String email, String password, String name) async {
    _setLoading(true);

    try {
      await _api.post(
        '/auth/register',
        body: {
          'email': email.trim(),
          'password': password,
          'name': name.trim(),
        },
      );

      await _api.clearToken();
      _currentUser = null;
      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return _messageFromError(e);
    }
  }

  Future<String?> login(String email, String password) async {
    _setLoading(true);

    try {
      final data = await _api.post(
        '/auth/login',
        body: {'email': email.trim(), 'password': password},
      );

      final token = data['token'] as String;
      await _api.saveToken(token);
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);

      _setLoading(false);
      return null;
    } catch (e) {
      _setLoading(false);
      return _messageFromError(e);
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    _currentUser = null;
    notifyListeners();
  }

  Future<String?> updateProfile(String name) async {
    if (_currentUser == null) return 'Chua dang nhap';

    try {
      final data = await _api.patch(
        '/auth/profile',
        body: {'name': name.trim()},
      );

      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      notifyListeners();
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_currentUser == null) return 'Chua dang nhap';

    try {
      await _api.patch(
        '/auth/password',
        body: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );
      return null;
    } catch (e) {
      return _messageFromError(e);
    }
  }

  String _messageFromError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Co loi xay ra: $error';
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
