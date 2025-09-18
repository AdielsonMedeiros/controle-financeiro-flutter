// lib/main.dart

import 'package:controle_financeiro_app/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true, // Adicionado para um visual mais moderno
      ),
      // A mágica acontece aqui! O AuthGate decide o que mostrar.
      home: const AuthGate(),
    );
  }
}