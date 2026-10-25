import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  List<dynamic> _locs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final devices = await context.read<ApiService>().get('/devices');
      if (devices.isNotEmpty) {
        _locs = await context.read<ApiService>().get('/locations/${devices[0]['deviceId']}');
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _timeAgo(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "À l'instant";
      if (diff.inHours < 1) return "Il y a ${diff.inMinutes} min";
      return "Il y a ${diff.inHours} h";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Historique GPS"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _locs.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.location_off_outlined, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("Aucune position reçue", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locs.length,
                    itemBuilder: (_, i) {
                      final l = _locs[i];
                      final ago = _timeAgo(l['recordedAt'].toString());
                      final isRecent = ago.contains("instant") || ago.contains("min");
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isRecent ? 4 : 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        color: isRecent ? Colors.white : Colors.grey[100],
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: isRecent ? Colors.red[50] : Colors.grey[200], shape: BoxShape.circle),
                            child: Icon(Icons.location_on_rounded, color: isRecent ? Colors.red[700] : Colors.grey[500]),
                          ),
                          title: Text(
                            "${l['latitude'].toString().substring(0, 7)}, ${l['longitude'].toString().substring(0, 7)}",
                            style: TextStyle(fontWeight: isRecent ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Text(
                            "Précision: ${l['accuracy']}m • $ago",
                            style: TextStyle(color: isRecent ? Colors.red[700] : Colors.grey[600]),
                          ),
                          trailing: isRecent
                              ? Chip(label: const Text("RÉCENT"), backgroundColor: Colors.red[100], labelStyle: TextStyle(color: Colors.red[800], fontSize: 10))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
