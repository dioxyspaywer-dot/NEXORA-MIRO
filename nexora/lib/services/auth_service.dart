import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  final ApiService _api = ApiService();

  Future<void> checkAuth() async {
    final token = await _api.getToken();
    _isLoggedIn = token != null && token.isNotEmpty;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final res = await _api.post('/auth/login', {'email': email, 'password': password}, auth: false);
    if (res.containsKey('token')) {
      await _api.saveToken(res['token']);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String email, String password, String fn, String ln) async {
    final res = await _api.post('/auth/register', {'email': email, 'password': password, 'firstName': fn, 'lastName': ln}, auth: false);
    if (res.containsKey('token')) {
      await _api.saveToken(res['token']);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _isLoggedIn = false;
    notifyListeners();
  }
}
