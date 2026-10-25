import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('Paramètres')),body:ListView(children:[
  ListTile(title:const Text('Se déconnecter'),onTap:()async{await context.read<AuthService>().logout();if(context.mounted)Navigator.pushAndRemoveUntil(context,MaterialPageRoute(builder:(_)=>const LoginScreen()),(_)=>false);}),
])); }