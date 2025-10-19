// lib/presentation/auth/register_screen.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/auth_service.dart';
import '../../theme/financial_gradients.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const RegisterScreen({super.key, required this.showLoginScreen});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String? result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // ALTERAÇÃO: A lógica de navegação foi removida, pois o AuthGate cuidará disso.
    // Apenas mostramos as mensagens de sucesso ou erro.
    if (result == "Cadastro realizado com sucesso" && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              "Cadastro realizado! Verifique seu e-mail para continuar."),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result ?? "Ocorreu um erro desconhecido."),
          backgroundColor: Theme.of(context).colorScheme.error));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final inputDecorationTheme = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.primary,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color: theme.colorScheme.error,
          width: 2.0,
        ),
      ),
    );

    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDarkMode
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.primary,
      foregroundColor: isDarkMode
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: FinancialGradients.backgroundSubtle(context),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/icon_logo.png',
                  height: 100,
                  color: isDarkMode ? Colors.white : null,
                ),
                const SizedBox(height: 24),
                Text(
                  'Crie sua conta',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'É rápido e fácil!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Email',
                          prefixIcon: const Icon(PhosphorIcons.at),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu email';
                          }
                          if (!value.contains('@')) {
                            return 'Por favor, insira um email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: inputDecorationTheme.copyWith(
                          labelText: 'Senha',
                          prefixIcon: const Icon(PhosphorIcons.lock),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira sua senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        decoration: BoxDecoration(
                          gradient: FinancialGradients.success,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: elevatedButtonStyle.copyWith(
                            backgroundColor: MaterialStateProperty.all(Colors.transparent),
                            shadowColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: _signUp,
                          child: const Text('CADASTRAR'),
                        ),
                      ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.showLoginScreen,
                  child: RichText(
                    text: TextSpan(
                      text: 'Já tem uma conta? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Faça login',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}