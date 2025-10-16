// lib/presentation/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final bool _isSocialLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWith(Future<String?> signInMethod) async {
    if (_isLoading || _isSocialLoading) return;

    setState(() {
      _isLoading = true;
    });

    String? result = await signInMethod;

    if (result != "Logado com sucesso" && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result ?? "Ocorreu um erro."),
          backgroundColor: Theme.of(context).colorScheme.error));
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // =======================================================================
  // A MELHORIA NO LAYOUT ESTÁ NESTA FUNÇÃO
  // =======================================================================
  void _showPasswordResetDialog() {
    final resetEmailController = TextEditingController();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Replicando o estilo dos inputs da tela de login
    final dialogInputDecoration = InputDecoration(
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHighest,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      labelText: 'E-mail',
      prefixIcon: const Icon(PhosphorIcons.at),
    );

    // Replicando o estilo dos botões
    final dialogElevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: isDarkMode
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.primary,
      foregroundColor: isDarkMode
          ? theme.colorScheme.onPrimaryContainer
          : theme.colorScheme.onPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0)),
              icon: const Icon(PhosphorIcons.key, size: 32),
              title: const Text("Recuperar Senha"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Digite seu e-mail para enviarmos um link de redefinição.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: resetEmailController,
                    decoration: dialogInputDecoration,
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("Cancelar"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: dialogElevatedButtonStyle,
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() => isSending = true);
                          final email = resetEmailController.text.trim();
                          if (email.isNotEmpty) {
                            final result = await _authService
                                .sendPasswordResetEmail(email: email);
                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text(result ?? "Erro desconhecido")),
                              );
                            }
                          } else {
                            setDialogState(() => isSending = false);
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text("Enviar Link"),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // =======================================================================
  // FIM DA ÁREA ALTERADA
  // =======================================================================

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

    final outlinedButtonStyle = OutlinedButton.styleFrom(
      foregroundColor: theme.colorScheme.onSurface,
      side: BorderSide(color: theme.colorScheme.outline),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
    );

    return Scaffold(
      body: SafeArea(
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
                  'Bem-vindo!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Faça login para continuar',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextButton(
                          onPressed: _showPasswordResetDialog,
                          child: const Text('Esqueceu a senha?'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    style: elevatedButtonStyle,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _signInWith(_authService.signIn(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        ));
                      }
                    },
                    child: const Text('ENTRAR'),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.showRegisterScreen,
                  child: RichText(
                    text: TextSpan(
                      text: 'Não tem uma conta? ',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Cadastre-se',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "OU",
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 24),
                if (_isSocialLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        style: outlinedButtonStyle,
                        icon:
                            Image.asset('assets/google_logo.png', height: 22.0),
                        label: const Text('Entrar com Google'),
                        onPressed: () =>
                            _signInWith(_authService.signInWithGoogle()),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: outlinedButtonStyle,
                        icon: Image.asset(
                          'assets/github_logo.png',
                          height: 22.0,
                          color: isDarkMode ? Colors.white : null,
                        ),
                        label: const Text('Entrar com GitHub'),
                        onPressed: () =>
                            _signInWith(_authService.signInWithGitHub()),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}