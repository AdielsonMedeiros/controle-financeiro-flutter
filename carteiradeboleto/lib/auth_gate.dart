import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'presentation/auth/login_or_register.dart';
import 'presentation/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Usuário está logado
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Usuário NÃO está logado
          else {
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}
