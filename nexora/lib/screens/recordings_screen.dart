import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../config/features.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});
  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  List<dynamic> _recordings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!Features.screenRecording) return;
    try {
      _recordings = await context.read<ApiService>().get('/recordings');
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!Features.screenRecording) {
      return Scaffold(
        appBar: AppBar(title: const Text('Enregistrements')),
        body: const Center(child: Text('Module désactivé')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Vidéos Écran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recordings.isEmpty
              ? const Center(child: Text('Aucun enregistrement'))
              : ListView.builder(
                  itemCount: _recordings.length,
                  itemBuilder: (_, i) {
                    final r = _recordings[i];
                    final duration = (r['durationMs'] / 1000).round();
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: const Icon(Icons.videocam, color: Colors.indigo),
                        title: Text("Session du ${r['recordedAt'].toString().substring(0, 10)}"),
                        subtitle: Text(
                            "Durée: ${duration}s - Taille: ${(r['fileSizeBytes'] / 1024 / 1024).toStringAsFixed(1)} Mo"),
                        trailing: IconButton(
                          icon: const Icon(Icons.download),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Téléchargement: ${r['_id']}')));
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
