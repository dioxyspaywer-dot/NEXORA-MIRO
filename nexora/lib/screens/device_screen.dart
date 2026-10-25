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
    // On appelle _load mais on ne met pas await ici pour ne pas bloquer l'UI
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<ApiService>().get('/devices');
      if (mounted) setState(() => _d = data);
    } catch (_) {
      // Si le serveur n'est pas encore configuré, on évite que l'app plante
      if (mounted) setState(() => _d = []);
    }
    if (mounted) setState(() => _l = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils'),
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
              ? const Center(child: Text('Aucun appareil associé'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _d.length,
                    itemBuilder: (_, i) {
                      final d = _d[i];
                      return ListTile(
                        title: Text(d['name'] ?? 'Sans nom'),
                        subtitle: Text('${d['manufacturer'] ?? ''} ${d['model'] ?? ''}\nÉtat: ${d['status']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Révoquer'),
                                content: Text('Révoquer ${d['name']} ?'),
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
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}