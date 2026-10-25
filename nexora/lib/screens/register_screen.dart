import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
class RegisterScreen extends StatefulWidget { const RegisterScreen({super.key}); @override State<RegisterScreen> createState() => _RegisterScreenState(); }
class _RegisterScreenState extends State<RegisterScreen> {
  final _e=TextEditingController(),_p=TextEditingController(),_fn=TextEditingController(),_ln=TextEditingController(); bool _l=false;
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('Inscription')),body:Padding(padding:const EdgeInsets.all(24),child:SingleChildScrollView(child:Column(children:[
    TextField(controller:_fn,decoration:const InputDecoration(labelText:'Prénom',border:OutlineInputBorder())), const SizedBox(height:12),
    TextField(controller:_ln,decoration:const InputDecoration(labelText:'Nom',border:OutlineInputBorder())), const SizedBox(height:12),
    TextField(controller:_e,decoration:const InputDecoration(labelText:'Email',border:OutlineInputBorder())), const SizedBox(height:12),
    TextField(controller:_p,obscureText:true,decoration:const InputDecoration(labelText:'Mot de passe',border:OutlineInputBorder())), const SizedBox(height:24),
    ElevatedButton(onPressed:_l?null:()async{setState(()=>_l=true);if(await context.read<AuthService>().register(_e.text,_p.text,_fn.text,_ln.text)){if(mounted)Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>const HomeScreen()));}else if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Échec inscription')));if(mounted)setState(()=>_l=false);},child:_l?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text("S'inscrire")),
  ]))));
}