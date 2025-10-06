// lib/screens/auth_screen.dart

import 'package:controle_financeiro_app/screens/forgot_password_screen.dart';
import 'package:controle_financeiro_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoginView = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  Future<void> _submitAuthForm() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, preencha todos os campos.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLoginView) {
        await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showErrorSnackbar('Ocorreu um erro. Tente novamente.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message = 'Ocorreu um erro inesperado.';
    switch (e.code) {
      case 'email-already-in-use':
        message = 'Este e-mail já está cadastrado. Tente fazer o login.';
        break;
      case 'weak-password':
        message = 'A senha é muito fraca. Tente uma senha mais forte.';
        break;
      case 'invalid-email':
        message = 'O formato do e-mail é inválido.';
        break;
      case 'user-not-found':
        message = 'Nenhum usuário encontrado com este e-mail.';
        break;
      case 'wrong-password':
        message = 'A senha está incorreta.';
        break;
      case 'account-exists-with-different-credential':
        message =
            'Já existe uma conta com este e-mail, mas com outro método de login.';
        break;
    }
    _showErrorSnackbar(message);
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitSocialLogin(Future<void> Function() loginMethod) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await loginMethod();
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showErrorSnackbar('Ocorreu um erro durante o login social.');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLoginView ? 'Bem-vindo de volta!' : 'Criar sua conta',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoginView
                        ? 'Faça login para continuar'
                        : 'Registre-se para começar',
                    style: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    obscureText: true,
                  ),
                  if (_isLoginView)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen()),
                            );
                          },
                          child: const Text('Esqueceu sua senha?'),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitAuthForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              _isLoginView ? 'Entrar' : 'Criar Conta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (_isLoginView) ...[
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.3))),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'Ou entre com',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withOpacity(0.3))),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _SocialLoginButton(
                                image: 'assets/gmail.png',
                                onPressed: () => _submitSocialLogin(
                                    _authService.signInWithGoogle),
                              ),
                              const SizedBox(width: 16),
                              _SocialLoginButton(
                                image: 'assets/social.png',
                                onPressed: () => _submitSocialLogin(
                                    _authService.signInWithGitHub),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLoginView = !_isLoginView;
                            });
                          },
                    child: Text(
                      _isLoginView
                          ? 'Não tem uma conta? Registre-se'
                          : 'Já tem uma conta? Faça o login',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
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

class _SocialLoginButton extends StatelessWidget {
  final String image;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.image,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Image.asset(image, height: 28),
        iconSize: 48,
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
