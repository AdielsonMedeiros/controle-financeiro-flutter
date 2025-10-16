// lib/ui/auth/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../presentation/auth/login_or_register.dart';
import '../../presentation/home/home_screen.dart';
import 'verify_email_screen.dart';


class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Se o usuário não está logado, mostra a tela de login/registro
        if (!snapshot.hasData) {
          return const LoginOrRegisterScreen();
        }

        final user = snapshot.data!;

        // Se o usuário está logado com email/senha mas não verificou,
        // mostra a tela de verificação.
        if (!user.emailVerified && user.providerData.any((info) => info.providerId == 'password')) {
          return const VerifyEmailScreen();
        }

        // Se tudo estiver certo, mostra a tela principal
        return const HomeScreen();
      },
    );
  }
}