import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/features.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<dynamic> _reports = [];
  bool _loading = true;
  String? _deviceId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!Features.activityReports) return;
    try {
      final devices = await context.read<ApiService>().get('/devices');
      if (devices.isNotEmpty) {
        _deviceId = devices[0]['deviceId'];
        _reports = await context.read<ApiService>().get('/reports/$_deviceId');
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!Features.activityReports) {
      return Scaffold(
        appBar: AppBar(title: const Text('Activité')),
        body: const Center(child: Text('Module désactivé')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Rapports d'activité")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? const Center(child: Text('Aucun rapport reçu de MIRO'))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    itemCount: _reports.length,
                    itemBuilder: (_, i) {
                      final r = _reports[i];
                      final hours = (r['totalScreenTimeMs'] / 3600000).toStringAsFixed(1);
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${r['date'].toString().substring(0, 10)}'),
                          subtitle: Text("Temps d'écran : $hours h"),
                          trailing: Text('${(r['appUsage'] as List).length} apps'),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
