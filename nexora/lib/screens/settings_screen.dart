import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Paramètres"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text("COMPTE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.indigo[50], child: Icon(Icons.person, color: Colors.indigo)),
                title: const Text("Mon Profil"),
                subtitle: const Text("Gérer mes informations"),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 1, indent: 70),
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.orange[50], child: Icon(Icons.lock, color: Colors.orange)),
                title: const Text("Sécurité"),
                subtitle: const Text("Modifier le mot de passe"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text("APPLICATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              ListTile(
                leading: CircleAvatar(backgroundColor: Colors.teal[50], child: Icon(Icons.info_outline, color: Colors.teal)),
                title: const Text("À propos"),
                subtitle: const Text("Version 1.0.0"),
                trailing: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await context.read<AuthService>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Se déconnecter"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red[700],
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
