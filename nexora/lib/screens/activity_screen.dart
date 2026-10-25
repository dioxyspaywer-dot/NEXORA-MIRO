import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<dynamic> _reports = [];
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
        _reports = await context.read<ApiService>().get('/reports/${devices[0]['deviceId']}');
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Activité"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? const Center(child: Text("Aucune donnée reçue. Ouvrez MIRO et accordez l'accès aux stats."))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder: (_, i) {
                        final r = _reports[i];
                        final totalMs = r['totalScreenTimeMs'] ?? 0;
                        final hours = (totalMs / 3600000).toStringAsFixed(1);
                        final apps = List<Map<String, dynamic>>.from(r['appUsage'] ?? []);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  Text("Rapport du ${r['date'].toString().substring(0, 10)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Chip(
                                    label: Text("$hours h"),
                                    backgroundColor: Colors.indigo[50],
                                    labelStyle: TextStyle(color: Colors.indigo[700]),
                                  ),
                                ]),
                                const Divider(height: 24),
                                const Text("Top Applications", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
                                const SizedBox(height: 8),
                                ...apps.map((app) {
                                  final appName = app['packageName'].toString().split('.').last;
                                  final ms = app['durationMs'];
                                  final mins = (ms / 60000).round();
                                  final percent = totalMs > 0 ? (ms / totalMs) : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      SizedBox(width: 100, child: Text(appName, overflow: TextOverflow.ellipsis)),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: percent.toDouble(),
                                            minHeight: 8,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SizedBox(width: 40, child: Text("$mins m", textAlign: TextAlign.right, style: const TextStyle(fontSize: 12))),
                                    ]),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      );
}
