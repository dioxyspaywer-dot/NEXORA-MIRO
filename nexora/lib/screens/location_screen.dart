import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/features.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  List<dynamic> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!Features.locationTracking) return;
    try {
      final devices = await context.read<ApiService>().get('/devices');
      if (devices.isNotEmpty) {
        final deviceId = devices[0]['deviceId'];
        _locations = await context.read<ApiService>().get('/locations/$deviceId');
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!Features.locationTracking) {
      return Scaffold(
        appBar: AppBar(title: const Text('Localisation')),
        body: const Center(child: Text('Module désactivé')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Historique Position')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? const Center(child: Text('Aucune position reçue'))
              : ListView.builder(
                  itemCount: _locations.length,
                  itemBuilder: (_, i) {
                    final l = _locations[i];
                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.red),
                      title: Text(
                          'Lat: ${l['latitude'].toString().substring(0, 6)}, Lng: ${l['longitude'].toString().substring(0, 6)}'),
                      subtitle: Text(
                          "Précision: ${l['accuracy']}m - ${l['recordedAt'].toString().substring(0, 19)}"),
                    );
                  },
                ),
    );
  }
}
