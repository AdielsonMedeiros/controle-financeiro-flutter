

import 'dart:async'; 

import 'package:controlefinanceiro/providers/theme_provider.dart';
import 'package:controlefinanceiro/screens/auth_gate.dart';
import 'package:controlefinanceiro/theme/app_themes.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  
  WidgetsFlutterBinding.ensureInitialized();

  
  await initializeDateFormatting('pt_BR', null);

  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  
  runZonedGuarded<Future<void>>(() async {
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Controle Financeiro',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const AuthGate(),
    );
  }
}