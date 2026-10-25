import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

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
    try {
      _recordings = await context.read<ApiService>().get('/recordings');
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _downloadVideo(String id, String date) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Téléchargement en cours...")));
    try {
      final token = await context.read<ApiService>().getToken();
      final savePath = "/storage/emulated/0/Download/Nexora/video_$date.mp4";
      await Dio().download(
        '${ApiService.baseUrl}/recordings/$id/download',
        savePath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Vidéo sauvée dans Download/Nexora")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(title: const Text("Vidéos Écran"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _recordings.isEmpty
                ? const Center(child: Text("Aucun enregistrement"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recordings.length,
                    itemBuilder: (_, i) {
                      final r = _recordings[i];
                      final duration = (r['durationMs'] / 1000).round();
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
                            child: Icon(Icons.videocam, color: Colors.indigo[700]),
                          ),
                          title: Text('Session du ${r['recordedAt'].toString().substring(0, 10)}'),
                          subtitle: Text('Durée: ${duration}s - ${(r['fileSizeBytes'] / 1024 / 1024).toStringAsFixed(1)} Mo'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () => _downloadVideo(r['_id'], r['recordedAt'].toString().substring(0, 10)),
                          ),
                        ),
                      );
                    },
                  ),
      );
}
