import 'package:flutter/material.dart';
import 'device_screen.dart';
import 'activity_screen.dart';
import 'location_screen.dart';
import 'recordings_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  final _s = const [
    DashboardTab(),
    DeviceScreen(),
    ActivityScreen(),
    LocationScreen(),
    RecordingsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: _s[_i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (i) => setState(() => _i = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard), label: 'Accueil'),
            NavigationDestination(icon: Icon(Icons.phone_android), label: 'Appareil'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Activité'),
            NavigationDestination(icon: Icon(Icons.location_on), label: 'Position'),
            NavigationDestination(icon: Icon(Icons.videocam), label: 'Vidéos'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Paramètres'),
          ],
        ),
      );
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Nexora')),
        body: const Center(child: Text('Tableau de bord — Toutes les fonctions sont activées !')),
      );
}
