// lib/main.dart

import 'dart:async'; // <--- ADICIONE ESTA LINHA
import 'package:flutter/foundation.dart'; // <--- ADICIONE ESTA LINHA

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // <--- ADICIONE ESTA LINHA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/services/notification_service.dart';
import 'data/services/theme_provider.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'ui/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- INÍCIO DO CÓDIGO DO CRASHLYTICS ---
  // Adiciona um tratador de erros para o Flutter
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Adiciona um tratador para erros assíncronos que não são
  // tratados pelo Flutter.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  // --- FIM DO CÓDIGO DO CRASHLYTICS ---

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Gerenciador de Boletos',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}