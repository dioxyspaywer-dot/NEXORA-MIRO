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

  String _formatAppName(String pkg) {
    final parts = pkg.split('.');
    return parts.last.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim().capitalize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Activité"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.bar_chart_rounded, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text("Aucun rapport reçu", style: TextStyle(color: Colors.grey[600])),
                  ]),
                )
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
                        margin: const EdgeInsets.only(bottom: 20),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Rapport du ${r['date'].toString().substring(0, 10)}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(20)),
                                    child: Text("$hours h", style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text("Top Applications", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 12)),
                              const SizedBox(height: 12),
                              ...apps.take(8).map((app) {
                                final appName = _formatAppName(app['packageName']);
                                final ms = app['durationMs'];
                                final mins = (ms / 60000).round();
                                final percent = totalMs > 0 ? (ms / totalMs) : 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 90, child: Text(appName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500))),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: percent.toDouble(),
                                            minHeight: 10,
                                            backgroundColor: Colors.grey[200],
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(width: 45, child: Text("${mins}m", textAlign: TextAlign.right, style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                                    ],
                                  ),
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
}

extension StringCasingExtension on String {
  String capitalize() => isEmpty ? this : "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
}
