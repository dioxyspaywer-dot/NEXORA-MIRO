import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'screens/splash_screen.dart';
void main() => runApp(MultiProvider(providers: [ChangeNotifierProvider(create:(_)=>AuthService()), Provider(create:(_)=>ApiService())], child: const NexoraApp()));
class NexoraApp extends StatelessWidget { const NexoraApp({super.key}); @override Widget build(BuildContext context) => MaterialApp(title:'Nexora', theme:ThemeData(primarySwatch:Colors.indigo,useMaterial3:true), home:const SplashScreen()); }