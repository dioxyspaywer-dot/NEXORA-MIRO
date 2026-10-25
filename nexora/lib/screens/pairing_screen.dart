import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
class PairingScreen extends StatefulWidget { const PairingScreen({super.key}); @override State<PairingScreen> createState() => _PairingScreenState(); }
class _PairingScreenState extends State<PairingScreen> {
  String? _code; bool _l=false;
  @override Widget build(BuildContext context) => Scaffold(appBar:AppBar(title:const Text('Associer un appareil')),body:Padding(padding:const EdgeInsets.all(24),child:Center(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
    if(_code!=null)...[Text('Code d\'association',style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:16),Text(_code!,style:const TextStyle(fontSize:48,fontWeight:FontWeight.bold,letterSpacing:8)),const SizedBox(height:16),const Text('Entrez ce code dans MIRO',textAlign:TextAlign.center)],
    if(_code==null)ElevatedButton(onPressed:_l?null:()async{setState(()=>_l=true);try{final r=await context.read<ApiService>().post('/pairing/generate-code',{});if(mounted)setState(()=>_code=r['code']);}catch(_){}if(mounted)setState(()=>_l=false);},child:_l?const SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):const Text('Générer un code')),
  ]))));
}