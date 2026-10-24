import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState() => _LoginScreenState(); }
class _LoginScreenState extends State<LoginScreen> {
  final _e=TextEditingController(), _p=TextEditingController(); bool _l=false;
  @override Widget build(BuildContext context) => Scaffold(body:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    Text('NEXORA',style:Theme.of(context).textTheme.headlineMedium), const SizedBox(height:32),
    TextField(controller:_e,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())), const SizedBox(height:16),
    TextField(controller:_p,obscureText:true,decoration:const InputDecoration(labelText:'Mot de passe',border:OutlineInputBorder())), const SizedBox(height:24),
    ElevatedButton(onPressed:_l?null:()async{setState(()=>_l=true);if(await context.read<AuthService>().login(_e.text,_p.text)){if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));}else if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Échec connexion')));if(mounted)setState(()=>_l=false);},child:_l?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('Se connecter')),
    TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const RegisterScreen())),child:const Text('Créer un compte')),
  ])));
}