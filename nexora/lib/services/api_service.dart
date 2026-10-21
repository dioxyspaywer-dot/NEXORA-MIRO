import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class ApiService {
  static const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://your-server.vercel.app/api');
  Future<String?> getToken() async => (await SharedPreferences.getInstance()).getString('token');
  Future<Map<String,dynamic>> post(String path, Map<String,dynamic> body, {bool auth=true}) async {
    final h = {'Content-Type':'application/json'};
    if(auth){final t=await getToken();if(t!=null)h['Authorization']='Bearer $t';}
    final r = await http.post(Uri.parse('$baseUrl$path'), headers:h, body:jsonEncode(body));
    return jsonDecode(r.body);
  }
  Future<List<dynamic>> get(String path) async {
    final t = await getToken();
    final r = await http.get(Uri.parse('$baseUrl$path'), headers:{'Authorization':'Bearer $t!'});
    return jsonDecode(r.body);
  }
  Future<Map<String,dynamic>> delete(String path) async {
    final t = await getToken();
    final r = await http.delete(Uri.parse('$baseUrl$path'), headers:{'Authorization':'Bearer $t!'});
    return jsonDecode(r.body);
  }
}