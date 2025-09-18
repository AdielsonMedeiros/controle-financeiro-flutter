// lib/screens/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:controle_financeiro_app/screens/auth_screen.dart';
import 'package:controle_financeiro_app/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Exibe uma tela de carregamento enquanto verifica o status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Se não tem usuário, mostra a tela de autenticação
        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        // Se tem usuário, mostra a tela principal do app
        return const HomeScreen();
      },
    );
  }
}