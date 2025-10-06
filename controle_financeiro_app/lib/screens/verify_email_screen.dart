// lib/screens/verify_email_screen.dart

import 'dart:async';

import 'package:controle_financeiro_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _checkVerificationTimer;
  Timer? _resendCountdownTimer;

  bool _canResendEmail = false;
  int _countdown = 30;

  @override
  void initState() {
    super.initState();
    startResendTimer();

    // Inicia um timer para verificar o status do e-mail periodicamente
    _checkVerificationTimer = Timer.periodic(
        const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _checkVerificationTimer?.cancel();
    _resendCountdownTimer?.cancel();
    super.dispose();
  }

  void startResendTimer() {
    setState(() => _canResendEmail = false);
    _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdown == 0) {
        _resendCountdownTimer?.cancel();
        if (mounted) setState(() => _canResendEmail = true);
      } else {
        if (mounted) setState(() => _countdown--);
      }
    });
  }

  Future<void> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload(); // Recarrega os dados do usuÃ¡rio do Firebase
    if (user.emailVerified) {
      _checkVerificationTimer?.cancel();
      _resendCountdownTimer?.cancel();
      // O AuthGate irÃ¡ redirecionar automaticamente.
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();

        // Reseta o timer
        setState(() => _countdown = 30);
        startResendTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('E-mail de verificaÃ§Ã£o reenviado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao reenviar e-mail: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('VerificaÃ§Ã£o de E-mail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
            tooltip: 'Cancelar e Sair',
          )
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Um link de verificaÃ§Ã£o foi enviado para:',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'seu e-mail',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Por favor, clique no link para ativar sua conta. Se nÃ£o o encontrar, verifique sua caixa de spam.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                onPressed: _canResendEmail ? _resendVerificationEmail : null,
                label: Text(_canResendEmail
                    ? 'Reenviar E-mail'
                    : 'Reenviar em ($_countdown)s'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
