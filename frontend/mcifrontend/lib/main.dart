import 'package:flutter/material.dart';
import 'package:mcifrontend/app.dart';
import 'package:mcifrontend/features/home/presentation/pages/map_page.dart' hide DayventureApp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'REMOVED',        // remplace par ton URL
    anonKey: 'REMOVED',                    // remplace par ta clé
  );
  final prefs = await SharedPreferences.getInstance();
  prefs.setString('test', 'hello');
  print('SharedPreferences ready');
  runApp(DayventureApp());
}
