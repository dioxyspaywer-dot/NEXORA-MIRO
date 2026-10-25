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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Historique GPS"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _locs.isEmpty
                ? const Center(child: Text("Aucune position GPS reçue."))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _locs.length,
                      itemBuilder: (_, i) {
                        final l = _locs[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                              child: Icon(Icons.location_on, color: Colors.red[700]),
                            ),
                            title: Text("${l['latitude'].toString().substring(0, 7)}, ${l['longitude'].toString().substring(0, 7)}"),
                            subtitle: Text("Précision: ${l['accuracy']}m • ${l['recordedAt'].toString().substring(11, 16)}"),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    ),
                  ),
      );
}
