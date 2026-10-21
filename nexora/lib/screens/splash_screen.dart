import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
class SplashScreen extends StatefulWidget { const SplashScreen({super.key}); @override State<SplashScreen> createState() => _SplashScreenState(); }
class _SplashScreenState extends State<SplashScreen> {
  @override void initState(){super.initState();_check();}
  Future<void> _check() async { await context.read<AuthService>().checkAuth(); if(!mounted)return; Navigator.pushReplacement(context, MaterialPageRoute(builder:(_)=>context.read<AuthService>().isLoggedIn?const HomeScreen():const LoginScreen())); }
  @override Widget build(BuildContext context) => const Scaffold(body:Center(child:CircularProgressIndicator()));
}