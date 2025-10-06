// lib/screens/auth_screen.dart

import 'package:controle_financeiro_app/screens/forgot_password_screen.dart'; // <<< IMPORTE A NOVA TELA
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
        const SnackBar(content: Text('Por favor, preencha todos os campos.')),
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

  // ... (outros métodos como handleAuthError, showErrorSnackbar, submitSocialLogin permanecem iguais)
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginView ? 'Login' : 'Registrar',
                style:
                    const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (_isLoginView)
                Text(
                  'Por favor, faça o login para continuar.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              // --- BOTÃO ADICIONADO AQUI ---
              if (_isLoginView)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                        );
                      },
                      child: const Text('Esqueceu sua senha?'),
                    ),
                  ),
                ),
              // -----------------------------
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitAuthForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_isLoginView ? 'Login' : 'Criar Conta'),
                      ),
                    ),
                    if (_isLoginView) ...[
                      const SizedBox(height: 24),
                      const Text('Ou entre com'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: () => _submitSocialLogin(_authService.signInWithGoogle),
                            icon: Image.asset( 'assets/gmail.png', height: 32),
                            iconSize: 40,
                          ),
                          const SizedBox(width: 24),
                          IconButton(
                            onPressed: () => _submitSocialLogin(_authService.signInWithGitHub),
                            icon: Image.asset( 'assets/github.png', height: 32),
                            iconSize: 40,
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              const SizedBox(height: 20),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}