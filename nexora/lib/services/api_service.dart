import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL du serveur NEXORA (hébergé sur Render)
  static const baseUrl = 'https://nexora-miro.onrender.com/api';

  // Render (offre gratuite) met le serveur en veille : le premier appel peut prendre ~50 s
  static const _timeout = Duration(seconds: 60);

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
      final r = await http.post(Uri.parse('$baseUrl$path'), headers: headers, body: jsonEncode(body)).timeout(_timeout);
      return jsonDecode(r.body);
    } catch (_) {
      // En cas d'erreur (pas de serveur, pas d'internet), on renvoie une erreur silencieuse au lieu de planter
      return {'error': 'Serveur injoignable'};
    }
  }

  Future<List<dynamic>> get(String path) async {
    try {
      final t = await getToken();
      final r = await http.get(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $t'}).timeout(_timeout);
      return jsonDecode(r.body);
    } catch (_) {
      return []; // Renvoie une liste vide au lieu de planter
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final t = await getToken();
      final r = await http.delete(Uri.parse('$baseUrl$path'), headers: {'Authorization': 'Bearer $t'}).timeout(_timeout);
      return jsonDecode(r.body);
    } catch (_) {
      return {'error': 'Serveur injoignable'};
    }
  }
}