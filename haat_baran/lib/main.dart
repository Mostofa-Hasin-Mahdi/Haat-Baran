import 'package:flutter/material.dart';
import 'views/login_page.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://znmpekxnaacdrnbsotch.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpubXBla3huYWFjZHJuYnNvdGNoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc1MDkyNTksImV4cCI6MjA4MzA4NTI1OX0.QDMkHZOhP5gV7Kgm24fgYyex1LvA_fvuO8Uiml-yPXI',
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haat Baran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF388e3c),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF388e3c),
          primary: const Color(0xFF388e3c),
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
