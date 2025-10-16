// lib/ui/auth/verify_email_screen.dart

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/auth_service.dart';
import 'auth_gate.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isEmailVerified = false;
  Timer? _verificationTimer;
  Timer? _resendCooldownTimer;
  int _resendCooldown = 0; // Para o contador regressivo
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!_isEmailVerified) {
      _sendVerificationEmail();

      _verificationTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _resendCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    await FirebaseAuth.instance.currentUser!.reload();
    setState(() {
      _isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
    });

    if (_isEmailVerified) _verificationTimer?.cancel();
  }

  Future<void> _sendVerificationEmail() async {
    // Não envia se já estiver em cooldown
    if (_resendCooldown > 0) return;

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      // Inicia o cooldown de 30 segundos
      setState(() => _resendCooldown = 30);
      _resendCooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_resendCooldown > 0) {
          setState(() => _resendCooldown--);
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar e-mail: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEmailVerified) {
      return const AuthGate();
    }

    final theme = Theme.of(context);
    final canResend = _resendCooldown == 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificação de E-mail'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                PhosphorIcons.envelopeSimple,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Verifique seu e-mail',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                'Um link de verificação foi enviado para:\n${FirebaseAuth.instance.currentUser?.email}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: canResend ? _sendVerificationEmail : null,
                icon: const Icon(PhosphorIcons.paperPlaneTilt),
                label: Text(canResend
                    ? 'Reenviar E-mail'
                    : 'Aguarde $_resendCooldown s'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _authService.signOut(),
                child: const Text('Cancelar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}