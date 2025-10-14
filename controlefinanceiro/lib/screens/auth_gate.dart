// lib/auth_gate.dart

import 'package:controlefinanceiro/screens/auth_screen.dart';
import 'package:controlefinanceiro/screens/tabs_screen.dart';
// Importe a nova tela de verificação que criaremos a seguir
import 'package:controlefinanceiro/screens/verify_email_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Se o usuário está logado
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // Verificamos se o e-mail dele foi verificado
          if (user.emailVerified) {
            // Se sim, vai para a tela principal
            return const TabsScreen();
          } else {
            // Se não, vai para a tela de verificação
            return const VerifyEmailScreen();
          }
        }
        
        // Se não está logado, vai para a tela de autenticação
        return const AuthScreen();
      },
    );
  }
}