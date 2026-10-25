import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  Future<void> checkAuth() async { _isLoggedIn = (await SharedPreferences.getInstance()).getString('token') != null; notifyListeners(); }
  Future<bool> login(String email, String password) async {
    try { final r = await ApiService().post('/auth/login',{'email':email,'password':password},auth:false);
      if(r.containsKey('token')){final p=await SharedPreferences.getInstance();await p.setString('token',r['token']);await p.setString('userId',r['userId']);_isLoggedIn=true;notifyListeners();return true;} return false;
    } catch(_){return false;}
  }
  Future<bool> register(String email, String password, String fn, String ln) async {
    try { final r = await ApiService().post('/auth/register',{'email':email,'password':password,'firstName':fn,'lastName':ln},auth:false);
      if(r.containsKey('token')){final p=await SharedPreferences.getInstance();await p.setString('token',r['token']);await p.setString('userId',r['userId']);_isLoggedIn=true;notifyListeners();return true;} return false;
    } catch(_){return false;}
  }
  Future<void> logout() async { await (await SharedPreferences.getInstance()).clear(); _isLoggedIn=false; notifyListeners(); }
}