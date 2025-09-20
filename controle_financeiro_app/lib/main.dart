

import 'package:controle_financeiro_app/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; 


abstract class AppColors {
  static const Color primaria = Color(0xFF4F46E5);
  static const Color fundo = Color(0xFFF8FAFC);
  static const Color container = Color(0xFFFFFFFF);
  static const Color texto = Color(0xFF1E293B);
  static const Color textoSuave = Color(0xFF64748B);
  static const Color sucesso = Color(0xFF10B981);
  static const Color erro = Color(0xFFEF4444);
  static const Color borda = Color(0xFFE2E8F0);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.fundo,
        primaryColor: AppColors.primaria,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaria,
          secondary: AppColors.sucesso,
          error: AppColors.erro,
          surface: AppColors.container,
          onSurface: AppColors.texto,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.fundo,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: AppColors.texto,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: AppColors.textoSuave),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}