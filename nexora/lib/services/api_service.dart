import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Pour l'instant, on pointe vers une URL vide ou locale pour éviter les crashs réseau
  static const baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000/api');

  Future<String?> getToken() async {
    try {
      return (await SharedPreferences.getInstance()).getString('token');
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body, {bool auth = true}) async {
    try {
      final headers = {'Content-Type': 'application/json'};
      if (auth) {
        final t = await getToken();
        if (t != null) headers['Authorization'] = 'Bearer $t';
      }
      final r = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (_) {
      // En cas d'erreur (pas de serveur, pas d'internet), on renvoie une erreur silencieuse au lieu de planter
      return {'error': 'Serveur injoignable'};
    }
  }

  Future<List<dynamic>> get(String path) async {
    try {
      final t = await getToken();
      final r = await http.get(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $t'}).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (_) {
      return []; // Renvoie une liste vide au lieu de planter
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final t = await getToken();
      final r = await http.delete(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $t'}).timeout(const Duration(seconds: 5));
      return jsonDecode(r.body);
    } catch (_) {
      return {'error': 'Serveur injoignable'};
    }
  }
}