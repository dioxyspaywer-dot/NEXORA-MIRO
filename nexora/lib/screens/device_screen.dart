import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'pairing_screen.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  List<dynamic> _d = [];
  bool _l = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<ApiService>().get('/devices');
      if (mounted) setState(() => _d = data);
    } catch (_) {
      if (mounted) setState(() => _d = []);
    }
    if (mounted) setState(() => _l = false);
  }

  String _timeAgo(String? dateStr) {
    if (dateStr == null) return "Jamais";
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return "À l'instant";
      if (diff.inHours < 1) return "Il y a ${diff.inMinutes} min";
      if (diff.inDays < 1) return "Il y a ${diff.inHours} h";
      return "Il y a ${diff.inDays} j";
    } catch (_) {
      return "";
    }
  }

  (Color, String) _statusInfo(String? status) {
    switch (status) {
      case 'online':
        return (Colors.green, 'En ligne');
      case 'syncing':
        return (Colors.orange, 'Synchronisation');
      case 'revoked':
        return (Colors.grey, 'Révoqué');
      default:
        return (Colors.redAccent, 'Hors ligne');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Appareils'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PairingScreen())),
          )
        ],
      ),
      body: _l
          ? const Center(child: CircularProgressIndicator())
          : _d.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.phone_android, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Aucun appareil associé', style: TextStyle(color: Colors.grey[600])),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _d.length,
                    itemBuilder: (_, i) {
                      final d = _d[i];
                      final (statusColor, statusLabel) = _statusInfo(d['status']);
                      final battery = d['batteryLevel'];
                      final charging = d['batteryCharging'] == true;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
                                    child: const Icon(Icons.smartphone, color: Colors.indigo, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(d['name'] ?? 'Sans nom', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                                        const SizedBox(height: 2),
                                        Row(children: [
                                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                                          const SizedBox(width: 6),
                                          Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13)),
                                        ]),
                                      ],
                                    ),
                                  ),
                                  if (battery != null)
                                    Row(children: [
                                      Icon(
                                        charging
                                            ? Icons.battery_charging_full
                                            : battery > 80
                                                ? Icons.battery_full
                                                : battery > 40
                                                    ? Icons.battery_5_bar
                                                    : battery > 15
                                                        ? Icons.battery_2_bar
                                                        : Icons.battery_alert,
                                        color: battery <= 15 && !charging ? Colors.red : Colors.grey[700],
                                        size: 22,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('$battery%', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                                    ]),
                                ],
                              ),
                              const Divider(height: 28),
                              _InfoRow(icon: Icons.business, label: 'Fabricant', value: d['manufacturer'] ?? '—'),
                              _InfoRow(icon: Icons.phone_iphone, label: 'Modèle', value: d['model'] ?? '—'),
                              _InfoRow(icon: Icons.android, label: 'Android', value: d['androidVersion'] ?? '—'),
                              _InfoRow(icon: Icons.schedule, label: 'Dernière activité', value: _timeAgo(d['lastSeenAt']?.toString())),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Révoquer'),
                                        content: Text("Révoquer l'accès de ${d['name']} ?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Révoquer')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await context.read<ApiService>().delete('/devices/${d['deviceId']}');
                                      _load();
                                    }
                                  },
                                  icon: const Icon(Icons.link_off, color: Colors.red, size: 18),
                                  label: const Text('Révoquer', style: TextStyle(color: Colors.red)),
                                ),
                              ),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[500]),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      );
}
