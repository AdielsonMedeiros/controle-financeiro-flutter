// lib/screens/auth_screen.dart

import 'package:controle_financeiro_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importe o FirebaseAuth
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

  // Função para lidar com o clique no botão (VERSÃO ATUALIZADA)
  Future<void> _submitAuthForm() async {
    // Validação básica
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
      // Traduz o código de erro técnico para uma mensagem amigável
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
      }
      
      // Mostra a mensagem amigável na tela
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } catch (e) {
      // Tratamento para qualquer outro tipo de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ocorreu um erro. Tente novamente.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitAuthForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isLoginView ? 'Entrar' : 'Criar Conta'),
                  ),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
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